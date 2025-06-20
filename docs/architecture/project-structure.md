# OpenShift Virtualization Reference Architecture

## Project Structure Design

This document explains the architectural decisions and structure of the OpenShift Virtualization reference project.

## 🎯 Design Principles

### 1. **Multi-Tool Support**
The project supports multiple deployment and management approaches:
- **Kustomize**: For environment-specific configurations
- **Helm**: For templated, parameterized deployments  
- **Ansible**: For end-to-end automation and orchestration
- **GitOps**: For continuous deployment and drift detection

### 2. **Environment Agnostic**
Components are designed to work across different environments:
- **Cloud Providers**: AWS, Azure, GCP with networking restrictions
- **Bare Metal**: Physical servers with direct hardware access
- **Hybrid**: Mixed environments with different networking models

### 3. **AI/RAG Optimization**
Structure optimized for consumption by AI systems:
- **Semantic Metadata**: Consistent annotation schemas
- **Clear Documentation**: Template-driven documentation
- **Component Relationships**: Explicit dependency mapping

### 4. **Production Readiness**
Includes operational concerns from day one:
- **Testing Framework**: Validation and integration tests
- **Monitoring**: Observability configurations
- **Security**: RBAC, SCCs, and network policies

## 📁 Directory Structure

```
ocp-virt-reference/
├── base/                    # Foundation Kubernetes manifests
├── examples/                # Complete working scenarios
├── kustomize/              # Environment-specific overlays  
├── helm/                   # Templated chart deployments
├── ansible/                # Automation and orchestration
├── gitops/                 # Continuous deployment configs
├── docs/                   # Documentation and tutorials
├── tests/                  # Testing and validation
├── scripts/                # Utility and helper scripts
└── metadata/               # AI/RAG optimization data
```

### Base Manifests (`base/`)

**Purpose**: Raw Kubernetes manifests organized by functional area

```
base/
├── namespaces/             # Namespace definitions
├── network/                # Networking configurations
│   ├── overlay/           # Cloud-compatible overlay networks
│   ├── localnet/          # Bare-metal localnet networks
│   ├── linux-bridges/    # Linux bridge configurations
│   └── sr-iov/            # High-performance SR-IOV
├── storage/                # Storage configurations
│   ├── csi/               # Container Storage Interface
│   ├── hostpath/          # Local hostpath storage
│   ├── ceph/              # Ceph distributed storage
│   ├── lvm/               # LVM storage
│   └── nfs/               # Network File System
├── security/               # Security policies
│   ├── rbac/              # Role-based access control
│   ├── scc/               # Security Context Constraints
│   └── network-policies/  # Network isolation policies
├── operators/              # Operator configurations
│   ├── cnv/               # OpenShift Virtualization
│   ├── nmstate/           # Network configuration
│   └── lvm/               # LVM operator
└── system-images/          # VM images and templates
```

**Design Decision**: Separate by functional area rather than technology to make it easier for users to find what they need.

### Examples (`examples/`)

**Purpose**: Complete, working scenarios that demonstrate real-world usage

```
examples/
├── virtual-machines/       # VM examples by OS
│   ├── linux/
│   │   ├── fedora/        # Fedora-specific VMs
│   │   ├── rhel/          # RHEL-specific VMs
│   │   └── ubuntu/        # Ubuntu-specific VMs
│   └── windows/
│       ├── server-2022/   # Windows Server VMs
│       └── windows-11/    # Windows desktop VMs
├── templates/              # Reusable templates
│   ├── vm-templates/      # VirtualMachine templates
│   └── data-volume-templates/ # DataVolume templates
└── workloads/              # Application-specific examples
    ├── databases/         # Database workloads
    ├── web-servers/       # Web server configurations
    └── development/       # Development environments
```

**Design Decision**: Organize by operating system and workload type as these are the primary ways users think about VMs.

### Kustomize (`kustomize/`)

**Purpose**: Environment-specific configurations using Kustomize overlays

```
kustomize/
├── base/                   # Base kustomization
│   ├── kustomization.yaml
│   └── components/        # Reusable components
├── overlays/              # Environment-specific overlays
│   ├── development/       # Dev environment config
│   ├── staging/           # Staging environment config
│   ├── production/        # Production environment config
│   └── cloud-providers/   # Cloud-specific overlays
│       ├── aws/           # AWS-specific configurations
│       ├── azure/         # Azure-specific configurations
│       └── gcp/           # GCP-specific configurations
└── components/            # Reusable components
    ├── monitoring/        # Observability stack
    ├── backup/            # Backup configurations
    └── disaster-recovery/ # DR configurations
```

**Design Decision**: Separate by environment lifecycle and cloud provider to enable easy promotion and cloud-specific optimizations.

### Helm (`helm/`)

**Purpose**: Templated deployments with parameter-driven configuration

```
helm/
├── ocp-virt-platform/     # Main platform chart
│   ├── Chart.yaml
│   ├── values.yaml        # Default values
│   ├── values-examples/   # Example value files
│   │   ├── cloud.yaml     # Cloud environment values
│   │   ├── bare-metal.yaml # Bare-metal values
│   │   └── minimal.yaml   # Minimal installation
│   └── templates/         # Helm templates
├── vm-workloads/          # VM-specific charts
└── charts/                # Chart dependencies
```

**Design Decision**: Single comprehensive chart with examples rather than many small charts to reduce complexity.

### Ansible (`ansible/`)

**Purpose**: End-to-end automation and orchestration

```
ansible/
├── playbooks/             # Main automation playbooks
│   ├── cluster-prep.yml   # Cluster preparation
│   ├── deploy-platform.yml # Platform deployment
│   ├── deploy-workloads.yml # Workload deployment
│   └── day2-operations.yml # Operational tasks
├── roles/                 # Reusable automation roles
│   ├── ocp-virt-setup/    # OpenShift Virt setup
│   ├── network-config/    # Network configuration
│   ├── storage-config/    # Storage configuration
│   └── vm-deployment/     # VM deployment
├── inventory/             # Environment inventories
│   ├── development/
│   ├── staging/
│   └── production/
└── group_vars/            # Variable definitions
```

**Design Decision**: Workflow-based playbooks with reusable roles to support both simple and complex deployment scenarios.

## 🔄 Usage Patterns

### 1. **Simple Deployment** (Kustomize)
```bash
# Deploy to development environment
kustomize build kustomize/overlays/development | oc apply -f -
```

### 2. **Parameterized Deployment** (Helm)
```bash
# Deploy with custom values
helm install ocp-virt helm/ocp-virt-platform -f values-custom.yaml
```

### 3. **Automated Deployment** (Ansible)
```bash
# End-to-end automation
ansible-playbook ansible/playbooks/deploy-platform.yml -i inventory/production
```

### 4. **Continuous Deployment** (GitOps)
```bash
# Apply ArgoCD application
oc apply -f gitops/argocd/applications/ocp-virt-platform.yaml
```

## 🤖 AI/RAG Optimization

### Metadata Schema
```yaml
metadata:
  annotations:
    docs.ocp-virt.io/category: "networking|storage|security|compute"
    docs.ocp-virt.io/complexity: "basic|intermediate|advanced"  
    docs.ocp-virt.io/environment: "cloud|bare-metal|hybrid"
    docs.ocp-virt.io/description: "Component description"
    docs.ocp-virt.io/prerequisites: "comma,separated,list"
    docs.ocp-virt.io/use-cases: "comma,separated,list"
```

### Documentation Templates
- **Purpose**: What the component does
- **Prerequisites**: What must be installed/configured first
- **Configuration**: Available options and their effects
- **Examples**: Working examples with different scenarios
- **Troubleshooting**: Common issues and solutions
- **Related**: Links to related components

### Semantic Naming
- **Environment Prefix**: `cloud-`, `bare-metal-`, `hybrid-`
- **Component Type**: `-nad-`, `-vm-`, `-storage-`, `-operator-`
- **Configuration**: `-static-`, `-dhcp-`, `-custom-`

This structure enables AI systems to understand component relationships, dependencies, and usage patterns for intelligent recommendations and troubleshooting. 