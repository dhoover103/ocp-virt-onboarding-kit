# LVM Storage for OpenShift 4.19

This directory contains the configuration and scripts for deploying LVM Storage on OpenShift 4.19. LVM Storage provides dynamic provisioning of persistent volumes using local storage devices.

## Overview

The LVM Storage solution consists of:
- **LVM Storage Operator**: Manages the lifecycle of LVM storage
- **LVMCluster**: Configures volume groups and storage classes
- **StorageClass**: Provides dynamic provisioning with TopoLVM CSI driver

## Prerequisites

- OpenShift 4.19+ cluster with worker nodes
- At least one available disk on worker nodes (not mounted or partitioned)
- Cluster admin permissions
- `oc` CLI tool configured

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   OpenShift Cluster                        │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │  Control Plane  │    │         Worker Nodes            │ │
│  │                 │    │                                 │ │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ ┌─────────────┐ │ │
│  │ │LVM Operator │ │    │ │  Extra Disk │ │ TopoLVM CSI │ │ │
│  │ │ Controller  │ │    │ │   (/dev/vdb)│ │   DaemonSet │ │ │
│  │ └─────────────┘ │    │ └─────────────┘ └─────────────┘ │ │
│  └─────────────────┘    │ ┌─────────────────────────────┐ │ │
│                         │ │     Volume Group (vg1)      │ │ │
│                         │ │  ┌─────┐ ┌─────┐ ┌─────┐   │ │ │
│                         │ │  │ PV1 │ │ PV2 │ │ PV3 │   │ │ │
│                         │ │  └─────┘ └─────┘ └─────┘   │ │ │
│                         │ └─────────────────────────────┘ │ │
│                         └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Files

### Operator Installation
- `base/operators/lvm/operator-group.yaml` - OperatorGroup for LVM operator
- `base/operators/lvm/subscription.yaml` - Subscription to install LVM operator
- `base/operators/lvm/kustomization.yaml` - Kustomize configuration

### Storage Configuration
- `base/storage/lvm/lvmcluster.yaml` - LVMCluster resource configuration
- `base/storage/lvm/storage-class.yaml` - StorageClass marked as default
- `base/storage/lvm/kustomization.yaml` - Kustomize configuration

## Disk Configuration

The default configuration expects your extra disk to be available at one of these paths:
- `/dev/vdb` (primary path for VMs)
- `/dev/sdb` (common for bare metal)
- `/dev/sdc` (alternative path)
- `/dev/nvme1n1` (NVMe drives)

### Customizing Disk Paths

Edit `base/storage/lvm/lvmcluster.yaml` to match your environment:

```yaml
spec:
  storage:
    deviceClasses:
    - name: vg1
      deviceSelector:
        paths:
        - /dev/your-disk-path  # Update this
```

## Quick Start

### 1. Verify Your Disk

First, check what disks are available on your worker nodes:

```bash
# Check available disks
for node in $(oc get nodes -l node-role.kubernetes.io/worker -o name); do
  echo "=== $node ==="
  oc debug $node -- chroot /host lsblk -d
done
```

### 2. Deploy LVM Storage

Use the automated deployment script:

```bash
# Run the deployment script
./scripts/setup/deploy-lvm-storage.sh
```

Or deploy manually:

```bash
# Create namespace (if not exists)
oc apply -f manifests/storage/lvm/namespace.yaml

# Deploy operator
oc apply -k base/operators/lvm/

# Wait for operator to be ready
oc wait --for=condition=Available=true deployment/lvm-operator-controller-manager -n openshift-storage --timeout=300s

# Deploy storage configuration
oc apply -k base/storage/lvm/

# Wait for LVMCluster to be ready
oc wait --for=condition=Ready=true lvmcluster/ocp-lvmcluster -n openshift-storage --timeout=600s
```

### 3. Validate Installation

```bash
# Run validation script
./scripts/validation/validate-lvm-storage.sh

# Or check manually
oc get storageclass
oc get lvmcluster -n openshift-storage
oc get pods -n openshift-storage
```

## Usage Examples

### Basic PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  # StorageClass is optional since lvms-vg1 is default
  storageClassName: lvms-vg1
```

### StatefulSet with LVM Storage

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
spec:
  serviceName: database
  replicas: 3
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          value: user
        - name: POSTGRES_PASSWORD
          value: password
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 20Gi
      # Uses default storage class (lvms-vg1)
```

## Monitoring and Troubleshooting

### Common Commands

```bash
# Check LVMCluster status
oc get lvmcluster -n openshift-storage
oc describe lvmcluster ocp-lvmcluster -n openshift-storage

# Check storage class
oc get storageclass
oc describe storageclass lvms-vg1

# Check persistent volumes
oc get pv
oc describe pv <pv-name>

# Check TopoLVM pods
oc get pods -n openshift-storage -l app.kubernetes.io/name=topolvm

# Check volume groups on nodes
oc debug node/<node-name> -- chroot /host vgs
oc debug node/<node-name> -- chroot /host pvs
```

### Volume Group Information

```bash
# Check volume group details
for node in $(oc get nodes -l node-role.kubernetes.io/worker -o name); do
  echo "=== $node ==="
  oc debug $node -- chroot /host vgs vg1
  oc debug $node -- chroot /host pvs
done
```

### Common Issues

1. **LVMCluster not Ready**
   - Check if disks are available and not in use
   - Verify disk paths in lvmcluster.yaml
   - Check operator logs: `oc logs -n openshift-storage deployment/lvm-operator-controller-manager`

2. **PVC Stuck in Pending**
   - Check if storage class exists
   - Verify TopoLVM pods are running
   - Check node affinity and resource availability

3. **Volume Group Creation Failed**
   - Ensure disks are not mounted or partitioned
   - Verify disk permissions and accessibility
   - Check for existing LVM metadata: `oc debug node/<node> -- chroot /host pvs`

## Configuration Options

### LVMCluster Configuration

```yaml
spec:
  storage:
    deviceClasses:
    - name: vg1
      default: true                    # Set as default device class
      deviceSelector:
        paths:                         # Specific disk paths
        - /dev/vdb
        optionalPaths:                 # Alternative paths
        - /dev/sdb
        forceWipeDevicesAndDestroyAllData: false  # Safety setting
      thinPoolConfig:
        name: thin-pool-1             # Thin pool name
        sizePercent: 90               # Percentage of VG for thin pool
        overprovisionRatio: 10        # Overprovisioning ratio
      volumeGroupName: vg1            # Volume group name
      fsType: ext4                    # Default filesystem type
```

### StorageClass Parameters

```yaml
parameters:
  csi.storage.k8s.io/fstype: ext4     # Filesystem type
  "topolvm.io/device-class": vg1      # Device class to use
provisioner: topolvm.io               # CSI driver
reclaimPolicy: Delete                 # Volume reclaim policy
volumeBindingMode: WaitForFirstConsumer  # Binding mode
allowVolumeExpansion: true            # Enable volume expansion
```

## Security Considerations

- LVM Storage requires privileged access to manage local storage
- The operator runs in the `openshift-storage` namespace with elevated permissions
- Volume groups are created on worker nodes with root access
- Always validate disk paths before deployment to avoid data loss

## Performance Tuning

### Thin Pool Configuration
- Adjust `sizePercent` based on expected usage (default: 90%)
- Set `overprovisionRatio` based on workload patterns (default: 10)
- Monitor thin pool usage to prevent out-of-space conditions

### Storage Class Optimization
- Use `WaitForFirstConsumer` binding mode for node affinity
- Enable `allowVolumeExpansion` for dynamic growth
- Choose appropriate filesystem types (ext4, xfs) based on workload

## Backup and Disaster Recovery

1. **Volume Group Backup**
   ```bash
   # Create VG metadata backup
   oc debug node/<node> -- chroot /host vgcfgbackup vg1
   ```

2. **Application Data Backup**
   - Use application-specific backup tools
   - Consider volume snapshots (if supported)
   - Implement regular backup schedules

3. **Disaster Recovery**
   - Document disk configurations
   - Maintain infrastructure as code
   - Test recovery procedures regularly

## Migration and Upgrades

### Operator Upgrades
- LVM Storage operator supports automatic upgrades
- Monitor cluster during upgrade process
- Validate storage functionality after upgrades

### OpenShift Upgrades
- LVM Storage is compatible with OpenShift upgrade process
- Ensure operator channel matches OpenShift version
- Test storage workloads after cluster upgrades

## Support and Resources

- [Red Hat LVM Storage Documentation](https://docs.openshift.com/container-platform/4.19/storage/persistent_storage/persistent_storage_local/persistent-storage-using-lvms.html)
- [TopoLVM Project](https://github.com/topolvm/topolvm)
- [OpenShift Storage Documentation](https://docs.openshift.com/container-platform/4.19/storage/understanding-persistent-storage.html) 