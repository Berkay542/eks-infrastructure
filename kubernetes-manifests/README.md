# Kubernetes Manifests

These manifests define Deployments, Services for the microservices application.

## ⚙️ CI/CD Workflow (Jenkins + ArgoCD)

This project follows a GitOps-based deployment strategy using **Jenkins** for CI and **ArgoCD** for CD.

### 🧪 Continuous Integration (Jenkins)
1. Jenkins builds the Docker images from source.
2. Tags the image with Git commit SHA or semantic version.
3. Pushes the image to DockerHub or Amazon ECR.
4. Updates the image tag in the Kubernetes manifest (`Deployment.yaml`) via `sed`, `kustomize`, or GitOps tooling.
5. Commits & pushes the updated manifests to the Git repository.

### 🚀 Continuous Delivery (ArgoCD)
- ArgoCD watches the Git repo and automatically syncs the updated manifests to your Kubernetes cluster.
- This ensures that your cluster always reflects the desired state defined in Git.

> 🔒 Pro tip: Make sure to **remove `resources.requests/limits` blocks** from `HorizontalPodAutoscaler` targets to avoid ArgoCD sync issues.

## ✅ Usage

You **don’t** apply these manifests directly. They are automatically deployed via ArgoCD once Jenkins updates them.



