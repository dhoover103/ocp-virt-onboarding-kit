#!/bin/bash

# Validate LVM Storage Configuration
# This script checks the health and configuration of LVM storage

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validation results
VALIDATION_PASSED=0
VALIDATION_FAILED=0

# Track validation result
track_result() {
    if [ $1 -eq 0 ]; then
        ((VALIDATION_PASSED++))
        log_success "$2"
    else
        ((VALIDATION_FAILED++))
        log_error "$2"
    fi
}

# Check if LVM operator is installed
check_operator() {
    log_info "Checking LVM Storage Operator..."
    
    if oc get subscription lvm-operator -n openshift-storage &>/dev/null; then
        track_result 0 "LVM operator subscription exists"
    else
        track_result 1 "LVM operator subscription not found"
        return
    fi
    
    if oc get deployment lvm-operator-controller-manager -n openshift-storage &>/dev/null; then
        local replicas_ready=$(oc get deployment lvm-operator-controller-manager -n openshift-storage -o jsonpath='{.status.readyReplicas}')
        local replicas_desired=$(oc get deployment lvm-operator-controller-manager -n openshift-storage -o jsonpath='{.spec.replicas}')
        
        if [ "$replicas_ready" = "$replicas_desired" ] && [ "$replicas_ready" -gt 0 ]; then
            track_result 0 "LVM operator deployment is ready ($replicas_ready/$replicas_desired)"
        else
            track_result 1 "LVM operator deployment not ready ($replicas_ready/$replicas_desired)"
        fi
    else
        track_result 1 "LVM operator deployment not found"
    fi
}

# Check LVMCluster status
check_lvmcluster() {
    log_info "Checking LVMCluster configuration..."
    
    if oc get lvmcluster ocp-lvmcluster -n openshift-storage &>/dev/null; then
        track_result 0 "LVMCluster ocp-lvmcluster exists"
        
        local status=$(oc get lvmcluster ocp-lvmcluster -n openshift-storage -o jsonpath='{.status.state}')
        if [ "$status" = "Ready" ]; then
            track_result 0 "LVMCluster status is Ready"
        else
            track_result 1 "LVMCluster status is not Ready (current: $status)"
        fi
    else
        track_result 1 "LVMCluster ocp-lvmcluster not found"
    fi
}

# Check storage class
check_storage_class() {
    log_info "Checking StorageClass configuration..."
    
    if oc get storageclass lvms-vg1 &>/dev/null; then
        track_result 0 "StorageClass lvms-vg1 exists"
        
        local is_default=$(oc get storageclass lvms-vg1 -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}')
        if [ "$is_default" = "true" ]; then
            track_result 0 "StorageClass lvms-vg1 is set as default"
        else
            track_result 1 "StorageClass lvms-vg1 is not set as default"
        fi
        
        local provisioner=$(oc get storageclass lvms-vg1 -o jsonpath='{.provisioner}')
        if [ "$provisioner" = "topolvm.io" ]; then
            track_result 0 "StorageClass uses correct provisioner (topolvm.io)"
        else
            track_result 1 "StorageClass uses incorrect provisioner ($provisioner)"
        fi
    else
        track_result 1 "StorageClass lvms-vg1 not found"
    fi
}

# Check volume groups on nodes
check_volume_groups() {
    log_info "Checking volume groups on nodes..."
    
    local nodes=$(oc get nodes -l node-role.kubernetes.io/worker --no-headers -o custom-columns=NAME:.metadata.name)
    
    if [ -z "$nodes" ]; then
        track_result 1 "No worker nodes found"
        return
    fi
    
    local vg_found=false
    for node in $nodes; do
        log_info "Checking volume groups on node: $node"
        
        local vgs=$(oc debug node/$node -- chroot /host vgs --noheadings -o vg_name 2>/dev/null | grep vg1 || true)
        if [ -n "$vgs" ]; then
            log_success "Found volume group 'vg1' on node $node"
            vg_found=true
            
            # Check volume group details
            oc debug node/$node -- chroot /host vgs vg1 2>/dev/null || true
        else
            log_warning "No volume group 'vg1' found on node $node"
        fi
    done
    
    if [ "$vg_found" = true ]; then
        track_result 0 "Volume group 'vg1' found on at least one node"
    else
        track_result 1 "Volume group 'vg1' not found on any node"
    fi
}

# Check CSI driver pods
check_csi_driver() {
    log_info "Checking CSI driver pods..."
    
    local node_pods=$(oc get pods -n openshift-storage -l app=topolvm-node --no-headers | wc -l)
    local controller_pods=$(oc get pods -n openshift-storage -l app=topolvm-controller --no-headers | wc -l)
    
    if [ "$node_pods" -gt 0 ]; then
        track_result 0 "TopoLVM node pods running ($node_pods pods)"
    else
        track_result 1 "No TopoLVM node pods found"
    fi
    
    if [ "$controller_pods" -gt 0 ]; then
        track_result 0 "TopoLVM controller pods running ($controller_pods pods)"
    else
        track_result 1 "No TopoLVM controller pods found"
    fi
    
    # Check pod status
    local failed_pods=$(oc get pods -n openshift-storage -l app.kubernetes.io/name=topolvm --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
    if [ "$failed_pods" -eq 0 ]; then
        track_result 0 "All TopoLVM pods are running"
    else
        track_result 1 "$failed_pods TopoLVM pods are not running"
    fi
}

# Test PVC creation
test_pvc_creation() {
    log_info "Testing PVC creation..."
    
    local test_pvc_name="lvm-validation-test-$(date +%s)"
    
    cat <<EOF | oc apply -f - &>/dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $test_pvc_name
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
EOF

    if oc wait --for=condition=Bound pvc/$test_pvc_name -n default --timeout=60s &>/dev/null; then
        track_result 0 "Test PVC created and bound successfully"
        
        # Check the underlying PV
        local pv_name=$(oc get pvc $test_pvc_name -n default -o jsonpath='{.spec.volumeName}')
        if [ -n "$pv_name" ]; then
            local storage_class=$(oc get pv $pv_name -o jsonpath='{.spec.storageClassName}')
            if [ "$storage_class" = "lvms-vg1" ]; then
                track_result 0 "PVC uses correct storage class (lvms-vg1)"
            else
                track_result 1 "PVC uses incorrect storage class ($storage_class)"
            fi
        fi
    else
        track_result 1 "Test PVC failed to bind"
    fi
    
    # Cleanup
    oc delete pvc $test_pvc_name -n default &>/dev/null || true
}

# Display system information
show_system_info() {
    log_info "System Information:"
    echo "===================="
    
    echo "OpenShift Version:"
    oc version --client=false 2>/dev/null | head -2 || echo "Unable to get version"
    echo
    
    echo "LVM Storage Resources:"
    echo "Namespaces:"
    oc get namespace openshift-storage 2>/dev/null || echo "  openshift-storage: Not found"
    echo
    
    echo "LVMCluster:"
    oc get lvmcluster -n openshift-storage 2>/dev/null || echo "  No LVMCluster found"
    echo
    
    echo "StorageClasses:"
    oc get storageclass | grep -E "(NAME|lvm|default)" || echo "  No LVM storage classes found"
    echo
    
    echo "Persistent Volumes:"
    oc get pv | grep -E "(NAME|topolvm)" || echo "  No TopoLVM persistent volumes found"
    echo
}

# Main validation function
main() {
    log_info "Starting LVM Storage validation..."
    echo
    
    check_operator
    check_lvmcluster
    check_storage_class
    check_volume_groups
    check_csi_driver
    test_pvc_creation
    
    echo
    echo "==============================================="
    echo "Validation Summary:"
    echo "==============================================="
    log_success "Passed: $VALIDATION_PASSED"
    if [ $VALIDATION_FAILED -gt 0 ]; then
        log_error "Failed: $VALIDATION_FAILED"
    else
        log_success "Failed: $VALIDATION_FAILED"
    fi
    echo "==============================================="
    
    if [ $VALIDATION_FAILED -eq 0 ]; then
        log_success "All validations passed! LVM storage is working correctly."
        exit 0
    else
        log_error "Some validations failed. Please check the issues above."
        echo
        show_system_info
        exit 1
    fi
}

# Handle script arguments
case "${1:-validate}" in
    "validate")
        main
        ;;
    "info")
        show_system_info
        ;;
    "help"|"-h"|"--help")
        echo "LVM Storage Validation Script"
        echo "Usage: $0 [validate|info|help]"
        echo "  validate  - Run full validation (default)"
        echo "  info      - Show system information"
        echo "  help      - Show this help message"
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 