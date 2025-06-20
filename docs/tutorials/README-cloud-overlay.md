# OVN-Kubernetes Overlay Networks for Cloud Environments

This section provides configurations for cloud environments where direct physical network access (localnet) is not possible due to cloud provider restrictions.

## Why Overlay for Cloud?

### Cloud Environment Limitations
- **No L2 Bridging**: Cloud providers don't allow direct L2 bridging between instances
- **Security Groups**: Cloud firewalls block non-standard protocols
- **Network Virtualization**: Physical interfaces are already virtualized
- **Instance Isolation**: Cloud networking enforces strict isolation

### Overlay Solution Benefits
- **Geneve Encapsulation**: Traffic is encapsulated and travels over existing cloud networking
- **Cloud Compatible**: Works within cloud provider network restrictions
- **Secure**: Leverages existing cloud security models
- **Scalable**: Scales with cloud infrastructure

## Topology Options

### 1. Layer2 Overlay (`ovn-k8s-overlay-nad-*-cloud.yaml`)
```yaml
"topology": "layer2"
```
- **Use Case**: VM-to-VM communication within the cluster
- **Behavior**: Creates a virtual L2 network using Geneve tunnels
- **Traffic Flow**: `VM → OVN L2 Switch → Geneve Tunnel → Destination VM`
- **Best For**: Applications requiring L2 adjacency

### 2. Layer3 Overlay (`ovn-k8s-overlay-nad-layer3-cloud.yaml`)
```yaml
"topology": "layer3"
```
- **Use Case**: Routed networks for distributed applications
- **Behavior**: Creates routed subnets with distributed routing
- **Traffic Flow**: `VM → OVN Router → Geneve Tunnel → Destination`
- **Best For**: Microservices and distributed applications

## Cloud-Specific Configurations

### Traffic Flow in Cloud Overlay

```
┌─────────────┐    Geneve     ┌─────────────┐
│   VM/Pod    │  Encapsulation │   VM/Pod    │
│  Instance A │◄──────────────►│  Instance B │
└─────────────┘   over Cloud   └─────────────┘
       │         Network              │
       ▼                              ▼
┌─────────────┐                ┌─────────────┐
│Cloud Network│                │Cloud Network│
│   (AWS/     │◄──────────────►│   (AWS/     │
│  Azure/GCP) │                │  Azure/GCP) │
└─────────────┘                └─────────────┘
```

### Performance Considerations

**Overhead**: 
- Additional encapsulation adds ~50-100 bytes per packet
- CPU overhead for encap/decap operations
- Typically 5-15% performance impact

**Optimization**:
- Use hardware offload if available (SR-IOV, DPDK)
- Consider larger MTU sizes to reduce packet overhead
- Monitor CPU usage on network-intensive workloads

## Deployment Examples

### For AWS/EKS Environment
```bash
# Layer2 overlay for VM clustering
oc apply -f ovn-k8s-overlay-nad-dhcp-cloud.yaml

# Static IP allocation
oc apply -f ovn-k8s-overlay-nad-static-cloud.yaml
```

### For Azure/AKS Environment
```bash
# Layer3 overlay for distributed apps
oc apply -f ovn-k8s-overlay-nad-layer3-cloud.yaml
```

### For GCP/GKE Environment
```bash
# Both layer2 and layer3 work well
oc apply -f ovn-k8s-overlay-nad-static-cloud.yaml
oc apply -f ovn-k8s-overlay-nad-layer3-cloud.yaml
```

## Verification Commands

### Check Geneve Tunnels
```bash
# Verify Geneve interfaces exist
oc debug node/<node-name>
chroot /host
ip link show type geneve

# Check OVN southbound database
ovn-sbctl show

# Monitor Geneve traffic
tcpdump -i any -n 'port 6081'
```

### Validate Network Connectivity
```bash
# Test connectivity between VMs on overlay network
oc rsh <vm-pod-name>
ping <target-vm-ip>

# Check OVN logical topology
ovn-nbctl show
```

## Security Considerations

### Cloud Security Groups
- Configure cloud security groups to allow Geneve (UDP 6081)
- Ensure inter-instance communication is permitted
- Consider network policies for additional security

### OVN Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: overlay-network-policy
spec:
  podSelector:
    matchLabels:
      network: overlay
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          network: overlay
```

## Troubleshooting

### Common Cloud Issues

1. **Geneve Traffic Blocked**
   ```bash
   # Check cloud security groups allow UDP 6081
   # Verify no firewall rules blocking Geneve
   ```

2. **MTU Issues**
   ```bash
   # Check if cloud network supports larger MTU
   # Adjust MTU in overlay configuration if needed
   ```

3. **Performance Problems**
   ```bash
   # Monitor CPU usage during network operations
   # Consider hardware acceleration options
   # Check for packet drops in cloud networking
   ```

## When to Use Each Approach

### Use Localnet (Physical Bridge) When:
- On-premises deployment
- Bare metal servers
- Direct hardware access required
- Maximum performance needed

### Use Overlay (Geneve) When:
- Cloud environments (AWS, Azure, GCP)
- Network isolation required
- Multi-tenant scenarios
- Cloud provider restrictions apply

## Migration Path

If moving from localnet to overlay:

1. **Test Performance**: Benchmark your workload with overlay networking
2. **Update Security**: Configure cloud security groups for Geneve
3. **Monitor Resources**: Watch CPU usage for encapsulation overhead
4. **Adjust MTU**: Optimize MTU sizes for your cloud environment
5. **Validate Connectivity**: Ensure all required ports are accessible 