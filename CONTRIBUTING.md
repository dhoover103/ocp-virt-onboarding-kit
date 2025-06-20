# Contributing to OpenShift Virtualization Reference Architecture

Thank you for your interest in contributing to this OpenShift Virtualization reference project! This project aims to be a comprehensive, flexible, and AI-friendly resource for deploying virtualization workloads on OpenShift.

## 🎯 Project Goals

- **Comprehensive Examples**: Cover all major OpenShift Virtualization use cases
- **Multi-Tool Support**: Support Kustomize, Helm, Ansible, and GitOps workflows
- **Environment Flexibility**: Work across cloud, bare-metal, and hybrid environments
- **AI/RAG Optimization**: Structure content for consumption by AI systems
- **Production Ready**: Include testing, monitoring, and operational best practices

## 📁 Project Structure

This project follows a structured approach with multiple entry points:

- **`base/`** - Base Kubernetes manifests organized by component type
- **`examples/`** - Complete working examples for common scenarios
- **`kustomize/`** - Kustomization configurations for different environments
- **`helm/`** - Helm charts for templated deployments
- **`ansible/`** - Automation playbooks and roles
- **`gitops/`** - ArgoCD and Flux configurations
- **`docs/`** - Comprehensive documentation with tutorials
- **`tests/`** - Testing framework and validation scripts

## 🛠️ How to Contribute

### Adding New Components

1. **Base Manifests**: Add raw Kubernetes YAML to appropriate `base/` subdirectory
2. **Examples**: Create complete working examples in `examples/`
3. **Documentation**: Add tutorials and troubleshooting guides
4. **Metadata**: Include RAG-friendly annotations and descriptions

### Component Standards

#### YAML Manifest Requirements
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-component
  annotations:
    # RAG-friendly metadata
    docs.ocp-virt.io/category: "networking|storage|security|compute"
    docs.ocp-virt.io/complexity: "basic|intermediate|advanced"
    docs.ocp-virt.io/environment: "cloud|bare-metal|hybrid"
    docs.ocp-virt.io/description: "Brief description of component purpose"
    docs.ocp-virt.io/prerequisites: "comma,separated,prerequisites"
    docs.ocp-virt.io/use-cases: "comma,separated,use-cases"
```

#### Documentation Standards
- **Purpose**: Clear explanation of what the component does
- **Prerequisites**: Required operators, configurations, or dependencies
- **Configuration Options**: Available parameters and their effects
- **Examples**: Working examples with different configurations
- **Troubleshooting**: Common issues and solutions
- **Related Components**: Links to related manifests or documentation

### Naming Conventions

#### Files and Directories
- Use kebab-case for file and directory names
- Include environment prefix: `cloud-`, `bare-metal-`, `hybrid-`
- Include component type: `-nad-`, `-vm-`, `-storage-`, `-operator-`
- Include configuration style: `-static-`, `-dhcp-`, `-custom-`

#### Examples
```
base/network/overlay/ovn-k8s-overlay-nad-static-cloud.yaml
base/storage/csi/ceph-rbd-storageclass-ssd.yaml
examples/virtual-machines/linux/fedora/fedora-vm-web-server.yaml
```

### Testing Requirements

All contributions should include:
- **Validation**: YAML syntax and Kubernetes API validation
- **Integration Tests**: Verify component works in target environments
- **Documentation Tests**: Ensure examples and tutorials work as documented

### Supported Environments

Contributions should consider these deployment scenarios:
- **Cloud Providers**: AWS, Azure, GCP, IBM Cloud
- **Bare Metal**: Physical servers with direct hardware access
- **Hybrid**: Mixed cloud and on-premises environments
- **Edge**: Resource-constrained environments

### AI/RAG Optimization

To make content consumable by AI systems:
- **Structured Metadata**: Use consistent annotation schemas
- **Clear Documentation**: Follow documentation templates
- **Semantic Naming**: Use descriptive, consistent naming patterns
- **Component Relationships**: Document dependencies and relationships

## 🔄 Development Workflow

### 1. Fork and Clone
```bash
git clone https://github.com/your-username/ocp-virt.git
cd ocp-virt
```

### 2. Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 3. Make Changes
- Add/modify components following project standards
- Include comprehensive documentation
- Add tests where applicable

### 4. Validate Changes
```bash
# Run validation scripts
./scripts/validation/validate-yaml.sh
./scripts/validation/validate-documentation.sh

# Run tests
./scripts/tests/run-tests.sh
```

### 5. Submit Pull Request
- Provide clear description of changes
- Include examples and use cases
- Link to any related issues

## 📋 Pull Request Checklist

- [ ] Changes follow project structure and naming conventions
- [ ] Components include RAG-friendly metadata annotations
- [ ] Documentation includes purpose, prerequisites, examples
- [ ] YAML manifests are syntactically valid
- [ ] Tests pass (if applicable)
- [ ] Examples work in target environments
- [ ] Changes are backward compatible

## 🆘 Getting Help

- **Issues**: Create GitHub issues for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Documentation**: Check `docs/` directory for detailed guides

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project.

## 🙏 Recognition

Contributors will be recognized in the project README and release notes. Thank you for helping make OpenShift Virtualization more accessible and easier to deploy! 