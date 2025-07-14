# OpenShift Virtualization Partner Labs Onboarding

**WARNING: This project is under active development and not recommended for production use yet. APIs, structure, and workflows may change without notice.**

A bite-size approach reference project for deploying virtualization workloads on OpenShift using multiple deployment strategies.

## Project Goals

The first goal of this project is to provide ready to go, digestible pieces of configurations, with companion manifests and step by step guides for new OpenShift virtualization adopters that have no to little previous OpenShift experience and need to run functional validation on their applications. On the roadmap we consider covering more complex subjects to help advanced engineers with custom networking or storage issues and eventually cover all topics of interest to any OpenShift virtuzalization user wanting to take bite-size approaches.

We also intend to publish when necessary and pertinent, automation startegies that may involve Ansible, Helm, Kustomize, GitOps tools and / or Hashicorp automation tools.

**WARNING: This project DOES NOT replace the official OpenShift Virtualization trainning, which is highly recommended, nor the official documentation. Instead it is supposed to serve as a complement and a facilitator to partner and customer engineers just getting started.**

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


## License

This project is licensed under the MIT License - see the LICENSE file for details.