#!/bin/bash

# Deploy LVM Storage for OpenShift 4.19
# This script sets up LVM storage operator and configures a default storage class

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

# Check if running as cluster admin
check_permissions() {
    log_info "Checking cluster permissions..."
    if ! oc auth can-i create namespaces --quiet; then
        log_error "Insufficient permissions. Please run as cluster-admin."
        exit 1
    fi
    log_success "Cluster admin permissions confirmed"
}

# Check available disks
check_disks() {
    log_info "Checking available disks on nodes..."
    
    # Get all worker nodes
    nodes=$(oc get nodes -l node-role.kubernetes.io/worker --no-headers -o custom-columns=NAME:.metadata.name)
    
    if [ -z "$nodes" ]; then
        log_error "No worker nodes found"
        exit 1
    fi
    
    log_info "Found worker nodes: $nodes"
    
    # Check for available disks
    for node in $nodes; do
        log_info "Checking disks on node: $node"
        oc debug node/$node -- chroot /host lsblk -d -o NAME,SIZE,TYPE | grep disk || true
    done
    
    log_warning "Please verify the disk path in lvmcluster.yaml matches your environment"
    log_warning "Common paths: /dev/vdb, /dev/sdb, /dev/sdc, /dev/nvme1n1"
}

# Deploy namespace
deploy_namespace() {
    log_info "Creating openshift-storage namespace..."
    
    if oc get namespace openshift-storage &>/dev/null; then
        log_warning "Namespace openshift-storage already exists"
    else
        oc apply -f manifests/storage/lvm/namespace.yaml
        log_success "Namespace created"
    fi
}

# Deploy LVM operator
deploy_operator() {
    log_info "Deploying LVM Storage Operator..."
    
    oc apply -k base/operators/lvm/
    
    log_info "Waiting for LVM operator to be ready..."
    timeout 300 oc wait --for=condition=Available=true deployment/lvm-operator-controller-manager -n openshift-storage || {
        log_error "Timeout waiting for LVM operator"
        exit 1
    }
    
    log_success "LVM Storage Operator deployed successfully"
}

# Deploy LVM cluster configuration
deploy_lvm_cluster() {
    log_info "Deploying LVM cluster configuration..."
    
    oc apply -k base/storage/lvm/
    
    log_info "Waiting for LVMCluster to be ready..."
    timeout 600 oc wait --for=condition=Ready=true lvmcluster/ocp-lvmcluster -n openshift-storage || {
        log_error "Timeout waiting for LVMCluster"
        log_info "Check cluster status with: oc get lvmcluster -n openshift-storage"
        exit 1
    }
    
    log_success "LVM cluster configuration deployed successfully"
}

# Validate storage class
validate_storage_class() {
    log_info "Validating storage class configuration..."
    
    if oc get storageclass lvms-vg1 &>/dev/null; then
        log_success "StorageClass lvms-vg1 created"
        
        # Check if it's set as default
        if oc get storageclass lvms-vg1 -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' | grep -q "true"; then
            log_success "StorageClass lvms-vg1 is set as default"
        else
            log_warning "StorageClass lvms-vg1 is not set as default"
        fi
    else
        log_error "StorageClass lvms-vg1 not found"
        exit 1
    fi
}

# Test storage functionality
test_storage() {
    log_info "Testing storage functionality with a test PVC..."
    
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: lvm-test-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

    log_info "Waiting for PVC to be bound..."
    timeout 60 oc wait --for=condition=Bound pvc/lvm-test-pvc -n default || {
        log_error "Test PVC failed to bind"
        oc describe pvc lvm-test-pvc -n default
        return 1
    }
    
    log_success "Test PVC bound successfully"
    
    # Cleanup test PVC
    oc delete pvc lvm-test-pvc -n default
    log_info "Test PVC cleaned up"
}

# Main execution
main() {
    log_info "Starting LVM Storage deployment for OpenShift 4.19"
    
    check_permissions
    check_disks
    
    read -p "Continue with LVM storage deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled"
        exit 0
    fi
    
    deploy_namespace
    deploy_operator
    deploy_lvm_cluster
    validate_storage_class
    
    if test_storage; then
        log_success "LVM Storage deployment completed successfully!"
        log_info "Your LVM storage is now ready and set as the default storage class"
    else
        log_warning "LVM Storage deployed but test failed. Check cluster status."
    fi
    
    log_info "Useful commands:"
    log_info "  oc get lvmcluster -n openshift-storage"
    log_info "  oc get storageclass"
    log_info "  oc get pv"
    log_info "  oc describe lvmcluster ocp-lvmcluster -n openshift-storage"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 