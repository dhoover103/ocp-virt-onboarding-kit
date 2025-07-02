# Fedora Overlay Router

This directory contains the Fedora-based router pod that acts as a NAT gateway between the OVN-Kubernetes overlay network and the default pod network, enabling VMs on the overlay network to reach external networks.

## Overview

The `fedora-overlay-router` pod provides:
- **NAT Gateway**: Translates traffic from overlay network (10.200.0.0/16) to pod network
- **Routing**: Forwards traffic between overlay and pod networks
- **Gateway Services**: Acts as default gateway for VMs on overlay network

## Files

- `fedora-overlay-router.yaml` - Router pod manifest
- `fedora-overlay-router-rbac.yaml` - Service account, SCC, and RBAC resources
- `README.md` - This documentation

## Prerequisites

- OpenShift 4.14+ with OVN-Kubernetes
- `vm-guests` namespace
- `ovn-overlay-static` NetworkAttachmentDefinition deployed
- VMs running on the overlay network
- Cluster administrator privileges (for SCC creation)

## Deployment

### 1. Deploy RBAC Resources (Cluster Admin Required)

```bash
# Deploy service account, SCC, and RBAC
oc apply -f fedora-overlay-router-rbac.yaml

# Verify SCC creation
oc get scc fedora-overlay-router-scc

# Verify service account
oc get sa fedora-overlay-router -n vm-guests
```

### 2. Deploy Router Pod

```bash
# Deploy the router pod
oc apply -f fedora-overlay-router.yaml

# Verify deployment
oc get pod fedora-overlay-router -n vm-guests

# Check pod status and capabilities
oc describe pod fedora-overlay-router -n vm-guests
```

## Router Pod Configuration (10.200.0.9)

### 1. Access the Router Pod

```bash
oc exec -it fedora-overlay-router -n vm-guests -- /bin/bash
```

### 2. Install Required Packages

```bash
dnf install -y iproute iptables iputils
```

### 3. Enable IP Forwarding

```bash
# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Make it persistent (if supported)
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
```

### 4. Set Up NAT Rules

```bash
# Get interface names
ip addr show

# Assuming eth0 is pod network and net1 is overlay network
# Replace with your actual interface names

# Enable NAT from overlay network (10.200.0.0/16) to pod network
iptables -t nat -A POSTROUTING -s 10.200.0.0/16 -o eth0 -j MASQUERADE

# Allow forwarding between interfaces
iptables -A FORWARD -i net1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o net1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow all traffic on overlay network
iptables -A FORWARD -i net1 -o net1 -j ACCEPT
```

### 5. Verify Router Pod Configuration

```bash
# Check interfaces and IPs
ip addr show

# Check routing table
ip route show

# Check NAT rules
iptables -t nat -L -n -v

# Check forwarding rules
iptables -L FORWARD -n -v
```

## VM Configuration

### 1. Access VM Console

```bash
oc console vm/fedora-ovn-overlay -n vm-guests
# Login with fedora/fedora
```

### 2. Configure VM Network

#### Find the overlay interface:
```bash
# Install network tools
sudo dnf install -y iproute iputils

# Check current network configuration
ip addr show
ip route show
```

#### Configure static route through router:
```bash
# Find your overlay interface (probably net1 or similar)
# Assuming overlay interface is net1 with IP 10.200.0.x

# Add default route via router pod
sudo ip route add default via 10.200.0.9 dev net1

# Or add specific routes for external networks
sudo ip route add 0.0.0.0/0 via 10.200.0.9 dev net1
```

#### Test connectivity:
```bash
# Test router reachability
ping 10.200.0.9

# Test external connectivity (if router NAT is working)
ping 8.8.8.8

# Check routing table
ip route show
```

## Persistent VM Configuration (Optional)

To make the route persistent in the VM, add to cloud-init:

```yaml
# Add to your VM's cloud-init userData:
runcmd:
  - ip route add default via 10.200.0.9 dev net1
  - echo "default via 10.200.0.9 dev net1" >> /etc/sysconfig/network-scripts/route-net1
```

## Verification Commands

### From Router Pod:
```bash
# Check if traffic is being forwarded
iptables -L -n -v

# Monitor traffic
tcpdump -i any icmp
```

### From VM:
```bash
# Test connectivity
ping 10.200.0.9  # Router pod
ping 8.8.8.8     # External (through NAT)

# Trace route
traceroute 8.8.8.8
```

## Troubleshooting

### If VM can't reach router:
```bash
# Check overlay network connectivity
ping 10.200.0.9
arp -a
```

### If router can't forward:
```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Check iptables rules
iptables -L -n -v
iptables -t nat -L -n -v
```

### Router Pod Security Context Issues:
If you get permission errors, you may need to add capabilities to the router pod:

```yaml
securityContext:
  capabilities:
    add: ["NET_ADMIN", "NET_RAW"]
```

## Network Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ External        │    │ Router Pod       │    │ VM on Overlay   │
│ Networks        │◄──►│ (10.200.0.9)     │◄──►│ (10.200.0.x)    │
│ (Internet)      │    │ - NAT Gateway    │    │                 │
└─────────────────┘    │ - IP Forwarding  │    └─────────────────┘
                       │ - iptables rules │
                       └──────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │ Pod Network      │
                       │ (Default)        │
                       └──────────────────┘
```

## Security Considerations

- Router pod runs without privileges by default
- Add minimal capabilities only if needed (`NET_ADMIN`, `NET_RAW`)
- iptables rules should be as restrictive as possible for production use
- Consider network policies to control traffic flow

## Additional Resources

- [OpenShift Networking Documentation](https://docs.openshift.com/container-platform/latest/networking/)
- [OVN-Kubernetes Overlay Networks](https://github.com/ovn-org/ovn-kubernetes)
- [Multus CNI Documentation](https://github.com/k8snetworkplumbingwg/multus-cni) 