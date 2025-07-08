# OpenShift Virtualization References

**WARNING: This project is under active development and not recommended for production use. APIs, structure, and workflows may change without notice.**

A comprehensive reference project for deploying virtualization workloads on OpenShift using multiple deployment approaches.

## Project Goals

- Comprehensive coverage of OpenShift Virtualization use cases
- Multiple deployment methodologies (Kustomize, Helm, Ansible, GitOps)
- Support for cloud, bare-metal, and hybrid environments
- Production-ready configurations with security and operational best practices

## Project Structure

### Raw Manifests (`manifests/`)
Raw Kubernetes YAML manifests organized by component type that serve as building blocks for all other deployment methods.

- `network/` - Networking configurations including overlay, SR-IOV, bridges, and UDN
- `storage/` - Storage solutions for LVM, NFS, iSCSI, and hostpath
- `operators/` - Platform operators for CNV, NMState, and LVM
- `security/` - RBAC, SCCs, and network policies
- `virtual-machines/` - VM definitions organized by operating system
- `templates/` - Reusable VM and storage templates
- `namespaces/` - Namespace definitions
- `system-images/` - Custom image configurations

### Automation (`automation/`)

- `kustomize/` - Environment-specific overlays and reusable components built on raw manifests
- `helm/` - Templated charts for parameterized deployments
- `ansible/` - End-to-end automation and orchestration with environment-specific inventories
- `gitops/` - Declarative deployment configurations for ArgoCD and Flux

### Documentation (`docs/`)
Comprehensive documentation covering architecture, tutorials, and troubleshooting.

- `architecture/` - System design and component relationships
- `tutorials/` - Step-by-step deployment guides
- `troubleshooting/` - Common issues and solutions

## Getting Started


## Prerequisites

- OpenShift 4.17+ cluster with OpenShift Virtualization operator
- CLI tools: `oc`, `kubectl`
- Optional: `kustomize`, `helm`, `ansible` depending on chosen approach

## Contributing

All contributions should follow the established directory structure and include appropriate documentation. See `CONTRIBUTING.md` for detailed guidelines.

## License

This project is licensed under the MIT License - see the LICENSE file for details.