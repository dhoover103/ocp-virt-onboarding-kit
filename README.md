# OpenShift Virtualization Reference Architecture

A comprehensive, flexible, and AI-friendly reference project for deploying virtualization workloads on OpenShift with multiple deployment approaches and extensive examples.

## Project Goals on the Roadmap

- **Comprehensive Coverage**: All major OpenShift Virtualization use cases
- **Multi-Tool Support**: Kustomize, Helm, Ansible, and GitOps workflows
- **Environment Flexibility**: Cloud, bare-metal, and hybrid environments
- **AI/RAG Optimized**: Structured for consumption by AI systems and virtual consultants
- **Production Ready**: Testing, monitoring, and operational best practices included

## Project Structure Explained

This project provides multiple entry points to accommodate different deployment preferences:

```
📁 ocp-virt-reference/
├── 📂 base/                    # Raw Kubernetes manifests by component type
├── 📂 examples/                # Complete working examples and scenarios
├── 📂 kustomize/              # Environment-specific overlays and components
├── 📂 helm/                   # Templated charts for parameterized deployments
├── 📂 ansible/                # End-to-end automation and orchestration
├── 📂 gitops/                 # ArgoCD and Flux configurations
├── 📂 docs/                   # Comprehensive documentation and tutorials
├── 📂 tests/                  # Testing framework and validation scripts
├── 📂 scripts/                # Utility and helper scripts
└── 📂 metadata/               # AI/RAG optimization data and schemas
```
## 📋 Components Overview

### 🌐 Networking
- **Overlay Networks**: Cloud-compatible Geneve encapsulation
- **Localnet Networks**: Direct physical network access for bare-metal
- **SR-IOV**: High-performance networking for demanding workloads
- **Linux Bridges**: Traditional bridging configurations
- **UDNs (user defined networks)**: primary networks defined by the user

### 💾 Storage
- **CSI Integration**: Container Storage Interface drivers
- **Hostpath Provisioner**: Local storage for development
- **Ceph**: Distributed storage for production
- **LVM**: Logical Volume Management
- **NFS**: Network File System integration

### 🔒 Security
- **RBAC**: Role-Based Access Control configurations
- **SCC**: Security Context Constraints for OpenShift
- **Network Policies**: Microsegmentation and traffic control

### 🎛️ Operators
- **OpenShift Virtualization (CNV)**: Core virtualization platform
- **NMState**: Network configuration management
- **LVM**: Storage management

### 🖥️ Virtual Machines
- **Linux VMs**: Fedora, RHEL, Ubuntu examples
- **Windows VMs**: Server 2022, Windows 11 configurations
- **Workload Examples**: Databases, web servers, development environments

## 📚 Documentation

### Architecture & Design
- [Project Structure](docs/architecture/project-structure.md)
- [Design Decisions](docs/architecture/)
- [Component Relationships](docs/architecture/)

### Tutorials & Guides
- [Network Setup Tutorial](docs/tutorials/)
- [Storage Configuration Guide](docs/tutorials/)
- [VM Deployment Walkthrough](docs/tutorials/)

### Troubleshooting
- [Common Issues](docs/troubleshooting/)
- [Debug Commands](docs/troubleshooting/)
- [Performance Tuning](docs/troubleshooting/)

## 🛠️ Usage Examples

### Deploy a VM with Overlay Network
```yaml
# Using base manifests
oc apply -f base/namespaces/vm-guests-namespace.yaml
oc apply -f base/network/overlay/ovn-k8s-overlay-nad-static-cloud.yaml
oc apply -f examples/virtual-machines/linux/fedora/fedora-vm1.yaml
```

### Kustomize Overlay for Development
```bash
# Deploy development environment with monitoring
kustomize build kustomize/overlays/development | oc apply -f -
```

### Helm with Custom Values
```bash
# Deploy with custom networking configuration
helm install my-platform helm/ocp-virt-platform \
  --set networking.overlay.static.subnets="10.100.0.0/16" \
  --set monitoring.enabled=true
```

## 🤖 AI/RAG Optimization

This project is optimized for consumption by AI systems and virtual consultants:

### Structured Metadata
All components include semantic annotations:
```yaml
metadata:
  annotations:
    docs.ocp-virt.io/category: "networking"
    docs.ocp-virt.io/complexity: "intermediate"
    docs.ocp-virt.io/environment: "cloud,bare-metal"
    docs.ocp-virt.io/description: "Overlay network for cloud environments"
    docs.ocp-virt.io/prerequisites: "cnv-operator"
    docs.ocp-virt.io/use-cases: "multi-tenant,isolation"
```

### Clear Documentation Templates
- **Purpose**: What the component does
- **Prerequisites**: Required dependencies
- **Configuration**: Available options
- **Examples**: Working scenarios
- **Troubleshooting**: Common issues

### Semantic Naming Conventions
- Environment-specific prefixes: `cloud-`, `bare-metal-`, `hybrid-`
- Component type indicators: `-nad-`, `-vm-`, `-storage-`
- Configuration style: `-static-`, `-dhcp-`, `-custom-`

## 🔧 Development & Contribution

### Prerequisites
- OpenShift 4.12+ cluster
- `oc` CLI tool
- `kubectl` and `kustomize` (for Kustomize workflows)
- `helm` v3.0+ (for Helm workflows)
- `ansible` 2.9+ (for Ansible workflows)

### Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines, coding standards, and development workflow.

### Testing
```bash
# Validate YAML syntax
./scripts/validation/validate-yaml.sh

# Run integration tests
./scripts/tests/run-integration-tests.sh

# Validate documentation
./scripts/validation/validate-documentation.sh
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenShift Virtualization team for the excellent platform
- KubeVirt community for the underlying technology
- Contributors and maintainers of this reference architecture

## 📞 Support & Community

- **Issues**: [GitHub Issues](https://github.com/acmenezes/ocp-virt/issues)
- **Discussions**: [GitHub Discussions](https://github.com/acmenezes/ocp-virt/discussions)
- **Documentation**: [docs/](docs/) directory

---

**Ready to deploy virtualization workloads on OpenShift?** Start with the [Quick Start](#-quick-start) section and choose your preferred deployment approach!


# Custom Networking


### SRIOV network cards and VFs


### Node network policies and nmstate operator


### Linux bridges as secondary custom networks


### Bridging through ovn-kubernetes

 
### Network attachment definitions and secondary nics


# Storage configuration for VMs

### Hostpath provisioner

### iSCSI

### NFS


# System Image customization

### sysprep and unattend.xml files

### linux and cloudinit


# Golden images and templates


