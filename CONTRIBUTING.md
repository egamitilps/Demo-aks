# Contributing to Retail Store AKS Infrastructure

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Contribution Workflow](#contribution-workflow)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)

## Code of Conduct

This project follows a code of conduct. By participating, you are expected to uphold this code:

- Be respectful and inclusive
- Welcome newcomers
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title** describing the issue
- **Detailed description** of the problem
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Environment details** (Azure region, AKS version, etc.)
- **Screenshots** if applicable
- **Error messages or logs**

### Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- **Clear use case** for the enhancement
- **Detailed description** of the proposed functionality
- **Alternative solutions** you've considered
- **Additional context** or screenshots

### Contributing Code

We welcome code contributions in these areas:

1. **Infrastructure Improvements**
   - Bicep template enhancements
   - New modules
   - Cost optimizations
   - Security improvements

2. **Documentation**
   - Fix typos or unclear instructions
   - Add examples
   - Improve architecture diagrams
   - Add tutorials

3. **CI/CD Enhancements**
   - Pipeline improvements
   - Add new workflows
   - Improve automation

4. **Application Code**
   - Frontend (React)
   - Backend (.NET)
   - Kubernetes manifests

## Development Setup

### Prerequisites

Ensure you have the following installed:

```bash
# Required tools
az --version        # Azure CLI 2.50.0+
bicep --version     # Latest Bicep CLI
kubectl version     # Kubernetes CLI
docker --version    # Docker
git --version       # Git

# Optional but recommended
helm version        # Helm 3.x
dotnet --version    # .NET 8 SDK (for backend)
node --version      # Node.js 18+ (for frontend)
```

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/Demo-aks.git
   cd Demo-aks
   ```

3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL-OWNER/Demo-aks.git
   ```

### Local Development Environment

1. **Configure Azure credentials**:
   ```bash
   az login
   az account set --subscription "Your-Subscription-Name"
   ```

2. **Create a development resource group**:
   ```bash
   az group create \
     --name rg-retail-dev-contributor \
     --location southcentralus
   ```

3. **Test Bicep templates**:
   ```bash
   az bicep build --file infra/bicep/main.bicep
   ```

## Contribution Workflow

### 1. Create a Branch

```bash
# Update your fork
git checkout main
git fetch upstream
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

### 2. Make Changes

- Write your code
- Follow coding standards (see below)
- Add tests if applicable
- Update documentation

### 3. Test Your Changes

```bash
# Validate Bicep
az bicep build --file infra/bicep/main.bicep

# Test deployment (what-if)
az deployment group what-if \
  --resource-group rg-retail-dev-contributor \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/dev.bicepparam

# Actually deploy to test (optional)
az deployment group create \
  --resource-group rg-retail-dev-contributor \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/dev.bicepparam
```

### 4. Commit Changes

```bash
git add .
git commit -m "type: brief description"
```

See [Commit Guidelines](#commit-guidelines) below.

### 5. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 6. Create Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select your branch
4. Fill out the PR template
5. Submit

## Coding Standards

### Bicep

- **Naming**: Use camelCase for parameters, PascalCase for resources
- **Comments**: Add descriptive comments for complex logic
- **Parameters**: Always include @description decorators
- **Outputs**: Document all outputs with @description
- **Resources**: Use latest stable API versions
- **Modules**: Keep modules focused and reusable

Example:
```bicep
@description('The name of the AKS cluster')
param aksClusterName string

@description('The location for all resources')
param location string = resourceGroup().location

// Create AKS cluster
resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: aksClusterName
  location: location
  properties: {
    // ... properties
  }
}

@description('The resource ID of the AKS cluster')
output aksClusterId string = aksCluster.id
```

### YAML (Pipelines)

- Use 2 spaces for indentation
- Add comments for complex steps
- Use descriptive names for jobs and steps
- Keep pipelines modular

### Markdown (Documentation)

- Use clear, concise language
- Include code examples
- Add table of contents for long documents
- Use proper heading hierarchy (H1 → H2 → H3)
- Include images or diagrams where helpful

### Code Formatting

- **Bicep**: Use built-in Bicep formatter
- **.NET**: Use `dotnet format`
- **JavaScript/React**: Use Prettier with ESLint

## Commit Guidelines

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

### Examples

```bash
# Feature
git commit -m "feat(aks): add support for spot instances"

# Bug fix
git commit -m "fix(sql): correct private endpoint DNS zone name"

# Documentation
git commit -m "docs(readme): add cost estimation section"

# Infrastructure
git commit -m "feat(monitoring): add Application Insights module"

# CI/CD
git commit -m "ci(github): add automated Bicep validation"
```

### Detailed Commit Example

```
feat(acr): add geo-replication support

Add optional geo-replication configuration to ACR module to support
multi-region deployments. This is behind a feature flag and disabled
by default to avoid additional costs.

Changes:
- Add geoReplication parameter to acr.bicep
- Update documentation with geo-replication examples
- Add cost warnings for geo-replication

Closes #123
```

## Pull Request Process

### PR Title

Use the same format as commits:
```
feat(module): brief description
```

### PR Description Template

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Bicep validation passed
- [ ] Deployment tested in dev environment
- [ ] Documentation updated
- [ ] No secrets committed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No warnings in Bicep build
- [ ] Tested deployment end-to-end

## Screenshots (if applicable)
Add screenshots here

## Related Issues
Closes #issue_number
```

### Review Process

1. **Automated Checks**: CI pipeline runs automatically
   - Bicep validation
   - Linting
   - Security scanning

2. **Code Review**: At least one maintainer reviews
   - Code quality
   - Documentation
   - Testing
   - Security implications

3. **Approval**: PR approved by maintainer

4. **Merge**: Maintainer merges using squash and merge

## Testing Guidelines

### Infrastructure Testing

1. **Bicep Validation**:
   ```bash
   az bicep build --file infra/bicep/main.bicep
   ```

2. **What-If Deployment**:
   ```bash
   az deployment group what-if \
     --resource-group rg-retail-dev \
     --template-file infra/bicep/main.bicep \
     --parameters infra/bicep/parameters/dev.bicepparam
   ```

3. **Actual Deployment** (in dev environment):
   ```bash
   az deployment group create \
     --resource-group rg-retail-dev-test \
     --template-file infra/bicep/main.bicep \
     --parameters infra/bicep/parameters/dev.bicepparam
   ```

4. **Verification**:
   ```bash
   # Verify resources
   az resource list --resource-group rg-retail-dev-test

   # Test AKS connectivity
   az aks get-credentials --name <aks-name> --resource-group rg-retail-dev-test
   kubectl get nodes

   # Test ACR
   az acr login --name <acr-name>
   ```

5. **Cleanup**:
   ```bash
   az group delete --name rg-retail-dev-test --yes --no-wait
   ```

### Application Testing

- **Backend**: Add unit tests with xUnit, integration tests
- **Frontend**: Add unit tests with Jest, E2E tests with Cypress
- **Kubernetes**: Test manifests with `kubectl --dry-run`

## Questions?

If you have questions:

1. Check existing documentation in `docs/`
2. Search existing issues on GitHub
3. Create a new issue with the `question` label
4. Join community discussions

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for contributing to the Retail Store AKS Infrastructure project! 🎉
