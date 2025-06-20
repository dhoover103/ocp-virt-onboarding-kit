# OVN-Kubernetes Secondary Networks for OpenShift Virtualization

This directory contains YAML manifests for configuring OVN-Kubernetes secondary networks using two different topologies: **Overlay Networks** (recommended for cloud environments) and **Localnet Networks** (for bare-metal/on-premises environments).

## When to Use Which Topology

### Use **Overlay Networks** when:
- ✅ Running in **cloud environments** (AWS, Azure, GCP, etc.)
- ✅ Need **Geneve encapsulation** for network isolation
- ✅ Want **cloud-compatible** networking that works with security groups
- ✅ Require **multi-tenant** network isolation

### Use **Localnet Networks** when:
- ✅ Running on **bare-metal** or **on-premises** environments
- ✅ Have **direct access** to physical network interfaces
- ✅ Need **direct L2 connectivity** to external networks
- ✅ Want **minimal network overhead** (no encapsulation)

> **⚠️ Important**: For detailed explanation of cloud networking restrictions, see [`cloud-networking-restrictions.md`](./cloud-networking-restrictions.md)

---

# 🌐 Overlay Networks (Cloud-Compatible)

Overlay networks use **Geneve encapsulation** and work in cloud environments where direct physical network access is restricted.

## Available Overlay Configurations

- **`ovn-k8s-overlay-nad-dhcp-cloud.yaml`** - Layer2 overlay with DHCP-like IP assignment
- **`ovn-k8s-overlay-nad-static-cloud.yaml`** - Layer2 overlay with static IP pools
- **`ovn-k8s-overlay-nad-layer3-cloud.yaml`** - Layer3 overlay for routed networks

## Prerequisites for Overlay Networks

- OpenShift 4.12+ with OVN-Kubernetes CNI
- OpenShift Virtualization operator installed
- Cluster running in cloud environment (AWS, Azure, GCP, etc.)

## Step-by-Step Overlay Deployment

### Step 1: Create the Target Namespace

```bash
# Create namespace for VMs (if it doesn't exist)
oc create namespace vm-guests
```

### Step 2: Deploy Overlay NetworkAttachmentDefinitions

Choose **ONE** of the following based on your IP management needs:

#### Option A: DHCP-like Behavior (Recommended)
```bash
oc apply -f ovn-k8s-overlay-nad-dhcp-cloud.yaml
```

#### Option B: Static IP Pool Management
```bash
oc apply -f ovn-k8s-overlay-nad-static-cloud.yaml
```

#### Option C: Layer3 Routed Network
```bash
oc apply -f ovn-k8s-overlay-nad-layer3-cloud.yaml
```

### Step 3: Verify Overlay Network Deployment

```bash
# Check NetworkAttachmentDefinitions
oc get net-attach-def -n vm-guests

# Expected output:
# NAME                  AGE
# ovn-overlay-dhcp      1m
```

### Step 4: Test Network Attachment

Create a test pod to verify the overlay network:

```bash
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-overlay-pod
  namespace: vm-guests
  annotations:
    k8s.v1.cni.cncf.io/networks: ovn-overlay-dhcp
spec:
  containers:
  - name: test
    image: registry.access.redhat.com/ubi8/ubi:latest
    command: ["/bin/bash", "-c", "sleep 3600"]
EOF
```

### Step 5: Verify Overlay Connectivity

```bash
# Check pod interfaces
oc exec -n vm-guests test-overlay-pod -- ip addr show

# Check connectivity between pods (create a second test pod)
oc exec -n vm-guests test-overlay-pod -- ping <secondary-pod-overlay-ip>

# Clean up test pod
oc delete pod test-overlay-pod -n vm-guests
```

### Step 6: Deploy VMs with Overlay Networks

Your VMs are ready to use the overlay network:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: test-vm-overlay
  namespace: vm-guests
spec:
  template:
    spec:
      networks:
      - name: default
        pod: {}
      - name: overlay-network
        multus:
          networkName: ovn-overlay-dhcp
      domain:
        devices:
          interfaces:
          - name: default
            masquerade: {}
          - name: overlay-network
            bridge: {}
        # ... rest of VM spec
```

---

# 🔗 Localnet Networks (Bare-Metal/On-Premises)

Localnet networks provide direct access to physical networks without encapsulation. Use only in bare-metal or on-premises environments.

## Available Localnet Configurations

- **`ovn-k8s-localnet-nad-dhcp.yaml`** - Direct DHCP from physical network
- **`ovn-k8s-localnet-nad-static.yaml`** - Static IP allocation with excludes
- **`ovn-k8s-localnet-nad-vlan.yaml`** - VLAN-tagged physical network access

## Prerequisites for Localnet Networks

- OpenShift 4.12+ with OVN-Kubernetes CNI
- OpenShift Virtualization operator installed
- **Bare-metal or on-premises** environment
- Physical network interface available on worker nodes
- NMState operator installed

## Step-by-Step Localnet Deployment

### Step 1: Install NMState Operator

```bash
# Create NMState operator subscription
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: kubernetes-nmstate-operator
  namespace: openshift-nmstate
spec:
  channel: stable
  name: kubernetes-nmstate-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# Wait for operator to be ready
oc wait --for=condition=Available deployment/nmstate-operator -n openshift-nmstate --timeout=300s
```

### Step 2: Configure Physical Interface Mapping

**🚨 IMPORTANT**: Update the physical interface name in `node-network-configuration-ovs.yaml`:

```bash
# First, identify your physical interface on worker nodes
oc debug node/<worker-node-name>
chroot /host
ip link show | grep -E "ens|eth|eno"
exit

# Edit the configuration file to match your interface
# Replace 'ens224' with your actual interface name
```

### Step 3: Apply Node Network Configuration

```bash
# Apply the NodeNetworkConfigurationPolicy
oc apply -f node-network-configuration-ovs.yaml

# Wait for configuration to be applied
oc get nncp ovs-br-mapping -w
# Wait until STATUS shows "Available"
```

### Step 4: Apply Cluster Network Configuration

```bash
# Apply cluster-level network mapping
oc apply -f cluster-network-physnet-mapping.yaml

# Verify cluster network configuration
oc get network.operator cluster -o yaml
```

### Step 5: Create Target Namespace

```bash
# Create namespace for VMs
oc create namespace vm-guests
```

### Step 6: Deploy Localnet NetworkAttachmentDefinitions

Choose **ONE** of the following based on your network requirements:

#### Option A: DHCP from Physical Network
```bash
oc apply -f ovn-k8s-localnet-nad-dhcp.yaml
```

#### Option B: Static IP Management
```bash
# Edit the subnet ranges first if needed
oc apply -f ovn-k8s-localnet-nad-static.yaml
```

#### Option C: VLAN-Tagged Network
```bash
# Edit VLAN ID and subnet if needed
oc apply -f ovn-k8s-localnet-nad-vlan.yaml
```

### Step 7: Verify Localnet Network Deployment

```bash
# Check NetworkAttachmentDefinitions
oc get net-attach-def -n vm-guests

# Check OVS bridge configuration on nodes
oc debug node/<worker-node-name>
chroot /host
ovs-vsctl show
ovs-vsctl list-br
```

### Step 8: Test Localnet Connectivity

Create a test pod with localnet attachment:

```bash
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-localnet-pod
  namespace: vm-guests
  annotations:
    k8s.v1.cni.cncf.io/networks: ovn-localnet-dhcp
spec:
  containers:
  - name: test
    image: registry.access.redhat.com/ubi8/ubi:latest
    command: ["/bin/bash", "-c", "sleep 3600"]
EOF
```

### Step 9: Verify Physical Network Access

```bash
# Check pod got IP from physical network DHCP
oc exec -n vm-guests test-localnet-pod -- ip addr show

# Test connectivity to physical network hosts
oc exec -n vm-guests test-localnet-pod -- ping <physical-network-host>

# Clean up test pod
oc delete pod test-localnet-pod -n vm-guests
```

### Step 10: Deploy VMs with Localnet Networks

Your VMs are ready to use the localnet network:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: test-vm-localnet
  namespace: vm-guests
spec:
  template:
    spec:
      networks:
      - name: default
        pod: {}
      - name: physical-network
        multus:
          networkName: ovn-localnet-dhcp
      domain:
        devices:
          interfaces:
          - name: default
            masquerade: {}
          - name: physical-network
            bridge: {}
        # ... rest of VM spec
```

---

# 🔧 Troubleshooting

## Common Issues

### Overlay Networks
- **Pods can't communicate**: Check if NetworkAttachmentDefinition exists and is in correct namespace
- **No IP assignment**: Verify subnet ranges don't conflict with existing networks
- **Geneve tunnel issues**: Check OVN-Kubernetes controller logs

### Localnet Networks
- **Interface not found**: Ensure physical interface name is correct in NNCP
- **Bridge mapping failed**: Verify OVS bridge configuration with `ovs-vsctl show`
- **No DHCP lease**: Check physical network DHCP server accessibility
- **Traffic not flowing**: Verify anti-spoofing and security policies

## Debug Commands

### For Overlay Networks
```bash
# Check OVN-Kubernetes logs
oc logs -n openshift-ovn-kubernetes -l app=ovnkube-master

# Check pod network attachments
oc describe pod <pod-name> -n <namespace>
```

### For Localnet Networks
```bash
# Check OVS configuration
oc debug node/<node-name>
chroot /host
ovs-vsctl list-br
ovs-vsctl list-ports br-ex

# Check NMState configuration
oc get nncp -o yaml

# Check physical interface status
oc debug node/<node-name>
chroot /host
ip link show <interface-name>
```

## Verification Checklist

Before creating VMs, ensure:

- [ ] NetworkAttachmentDefinition created successfully
- [ ] Test pod can attach to secondary network
- [ ] IP assignment working (DHCP or static)
- [ ] Network connectivity tested
- [ ] No errors in OVN-Kubernetes logs
- [ ] (Localnet only) OVS bridges configured correctly
- [ ] (Localnet only) Physical interface accessible

---

# 📚 Additional Resources

- [Cloud Networking Restrictions](./cloud-networking-restrictions.md) - Detailed explanation of why localnet fails in cloud
- [OpenShift Networking Documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/networking/multiple-networks)
- [OpenShift Virtualization Networking](https://docs.redhat.com/en/documentation/openshift_virtualization/)

## Customization Tips

- Modify namespace from `vm-guests` to your preference
- Adjust subnet ranges for your network topology
- Change VLAN IDs to match your network configuration
- Update interface names to match your hardware 