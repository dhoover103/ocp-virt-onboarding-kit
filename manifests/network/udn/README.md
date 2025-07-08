# User Defined Networks (UDN) - Primary Layer2 with Pod Service Access

This directory contains OpenShift User Defined Network (UDN) configurations that enable Virtual Machines to run on **Primary** Layer2 networks while maintaining access to pod network services.

## Overview

**Problem Solved**: VMs need to be completely isolated on their own network (no pod network interface) but still require access to cluster services running on the pod network.

**Solution**: Use OVN-Kubernetes **Primary** Layer2 User Defined Networks. The cluster's built-in service proxy and routing infrastructure automatically handles access to pod services.

## Primary vs Secondary UDN

### **Primary Role (This Configuration)**
- VM has **ONLY** the UDN network interface
- No pod network interface attached to VM
- All traffic routed through cluster networking infrastructure
- **Better isolation** and **cleaner network configuration**

### **Secondary Role (Alternative)**
- VM has **both** pod network interface AND UDN interface
- Direct access to pod network + secondary network
- More complex but more direct connectivity

## Prerequisites

- **OpenShift 4.18+** (UDN support)
- **OpenShift Virtualization** (CNV) installed
- **User Defined Networks** feature enabled on cluster
- Proper namespace labeling for UDN scope

## Components

### 1. User Defined Network (`vm-layer2-udn.yaml`)
Creates a **Primary** Layer2 network with:
- **Subnet**: `192.168.100.0/24`
- **Topology**: Layer2 (L2 switching within network)
- **Role**: **Primary** (replaces pod network entirely)
- **Scope**: Namespace-specific (`vm-guests`)

### 2. Network Attachment Definition (`vm-layer2-nad.yaml`)
Provides the CNI interface for VM attachment:
- **Type**: `ovn-k8s-cni-overlay`
- **Role**: **Primary** 
- **Persistent IPs**: Enabled for stable VM addressing
- **MTU**: 1400 (optimized for overlay)

## Network Architecture - Primary UDN

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenShift Cluster                        │
│                                                             │
│  ┌─────────────────┐           ┌─────────────────────────┐  │
│  │   Pod Network   │           │   Primary UDN Layer2   │  │
│  │  10.128.0.0/14  │◄──┐   ┌──►│   192.168.100.0/24    │  │
│  │                 │   │   │   │                        │  │
│  │  ┌─────────────┐ │   │   │   │  ┌─────────────────┐   │  │
│  │  │ Services    │ │   │   │   │  │      VMs       │   │  │
│  │  │ - DNS       │ │   │   │   │  │ - Fedora VM     │   │  │
│  │  │ - API       │ │   │   │   │  │ - Custom Apps   │   │  │
│  │  │ - Apps      │ │   │   │   │  │ (UDN only)      │   │  │
│  │  └─────────────┘ │   │   │   │  └─────────────────┘   │  │
│  └─────────────────┘   │   │   └─────────────────────────┘  │
│                        │   │                               │
│         ┌──────────────┘   └───────────────┐               │
│         │    Cluster Routing & Service     │               │
│         │    Proxy (OVN-LB/kube-proxy)     │               │
│         └──────────────────────────────────┘               │
│                                                             │
│  Primary UDN VMs route to services via cluster networking  │
└─────────────────────────────────────────────────────────────┘
```

## Key Differences with Primary UDN

### **Routing Behavior**
- VMs route to pod services through **cluster service proxy**
- **DNS queries** go through cluster DNS (172.30.0.10)
- **Service IPs** are routed via cluster networking, not direct pod network
- **Default gateway** configured in UDN routes traffic appropriately

### **Network Interface**
- VM has **single network interface** (eth0) on UDN
- **No pod network interface** (cleaner configuration)
- **Static IP configuration** within UDN subnet

### **Service Discovery**
- **Cluster DNS** still accessible from Primary UDN
- **Service names** resolve correctly (e.g., `kubernetes.default.svc.cluster.local`)
- **Service routing** handled by cluster infrastructure

## Deployment Order

```bash
# 1. Create namespace with proper labels
oc apply -f ../../namespaces/vm-guests-namespace.yaml

# 2. Create the Primary User Defined Network
oc apply -f vm-layer2-udn.yaml

# 3. Create Network Attachment Definition
oc apply -f vm-layer2-nad.yaml

# 4. Deploy example VM
oc apply -f ../../examples/virtual-machines/udn/fedora-vm-with-udn.yaml
```

## Quick Start with Makefile

```bash
# Deploy everything
make deploy-udn

# Start the VM
make start-vm

# Connect to VM console
make vm-console

# Check status
make status
```

## Verification Steps

### 1. Check Primary UDN Status
```bash
oc get userdefinednetworks -n vm-guests
oc describe userdefinednetwork vm-layer2-network -n vm-guests

# Verify Primary role
oc get udn vm-layer2-network -n vm-guests -o jsonpath='{.spec.layer2.role}'
```

### 2. Test VM Network Configuration
```bash
# Start the VM
oc patch vm fedora-vm-with-udn -n vm-guests --type merge -p '{"spec":{"running":true}}'

# Connect to VM console
virtctl console fedora-vm-with-udn -n vm-guests

# Inside VM, verify single interface configuration:
ip addr show        # Should show only eth0 with UDN IP
ip route show       # Should show default route via UDN gateway

# Test service connectivity:
nslookup kubernetes.default.svc.cluster.local
curl test-service-for-vm.vm-guests.svc.cluster.local:8080
curl -k https://kubernetes.default.svc.cluster.local/api/v1
```

## Advantages of Primary UDN

### **✅ Benefits**
- **Complete network isolation** - VM only on UDN
- **Cleaner configuration** - Single network interface
- **Better security posture** - No pod network exposure
- **Simplified routing** - All traffic via cluster networking
- **Resource efficiency** - One less network interface
- **Minimal setup** - No network policies needed in most cases

### **⚠️ Considerations**
- **Routing dependency** - Relies on cluster service proxy
- **DNS critical** - Cluster DNS must be accessible
- **Debugging complexity** - Network path is less direct

## Troubleshooting Primary UDN

### VM Cannot Reach Services

1. **Verify UDN Gateway Configuration**:
   ```bash
   # Inside VM
   ip route show
   # Should show: default via 192.168.100.1 dev eth0
   ```

2. **Test DNS Resolution**:
   ```bash
   # Inside VM
   nslookup kubernetes.default.svc.cluster.local
   dig @172.30.0.10 test-service-for-vm.vm-guests.svc.cluster.local
   ```

3. **Check Service Proxy Routing**:
   ```bash
   # On cluster
   oc get endpoints kubernetes -n default
   oc logs -n openshift-ovn-kubernetes deployment/ovnkube-control-plane | grep -i service
   ```

4. **Check for Existing Network Policies**:
   ```bash
   # If policies exist, they might be blocking traffic
   oc get networkpolicies -n vm-guests
   ```

### Performance Optimization

1. **MTU Configuration**: Ensure consistent MTU across network stack
2. **DNS Caching**: Consider local DNS caching in VM for better performance  
3. **Service Proxy**: Monitor service proxy performance for routing efficiency

## Configuration Options

### Custom Subnet
```yaml
# In vm-layer2-udn.yaml
spec:
  layer2:
    subnets: 
    - "10.200.0.0/24"  # Change to your preferred subnet
```

### Gateway Configuration
The UDN automatically configures appropriate gateways for routing to cluster services.

## When You Might Need Network Policies

Network policies are **optional** for this configuration, but you might need them if:

- Your namespace has existing restrictive network policies
- Security/compliance requirements demand explicit allow rules
- You need fine-grained control over VM-to-VM communication
- Cross-namespace access is required

If needed, network policies can be added later without disrupting the existing setup.

## Integration Examples

### With Ansible
```yaml
- name: Deploy Primary UDN networking
  kubernetes.core.k8s:
    state: present
    src: "{{ playbook_dir }}/base/network/udn/"
```

### With Kustomize
```yaml
# kustomization.yaml
resources:
- ../../../base/network/udn/
```

### With Helm
```yaml
# values.yaml
networking:
  udn:
    enabled: true
    role: "primary"
    subnet: "192.168.100.0/24"
    mtu: 1400
```

## Additional Resources

- [OpenShift User Defined Networks Documentation](https://docs.openshift.com/container-platform/4.18/networking/multiple_networks/understanding-multiple-networks.html)
- [OVN-Kubernetes Layer2 Configuration](https://github.com/ovn-org/ovn-kubernetes)
- [OpenShift Virtualization Networking](https://docs.openshift.com/container-platform/4.18/virt/vm_networking/virt-configuring-vm-network.html) 