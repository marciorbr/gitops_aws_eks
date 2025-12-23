# GitOps AWS EKS Project

This project provisions a comprehensive AWS infrastructure managed by Terraform, adhering to GitOps principles. It sets up a network environment (VPC) and two Amazon EKS clusters: a **Control Plane** cluster hosting ArgoCD and a **Worker** cluster for application workloads.

## Project Overview

The architecture is designed to separate the management plane (ArgoCD) from the workload plane.

*   **Region:** `us-east-1`
*   **Environment:** `dev`
*   **Infrastructure as Code:** Terraform
*   **GitOps Tool:** ArgoCD

## Architecture Components

### 1. Network (VPC)
*   **Module:** `github.com/marciorbr/terraform-aws-vpc`
*   **CIDR:** `10.200.0.0/18`
*   **Subnets:** Public, Private, and Database subnets across `us-east-1a` and `us-east-1b`.

### 2. EKS Control Plane (`control-plane`)
*   **Purpose:** Hosts the ArgoCD installation and management tools.
*   **Kubernetes Version:** 1.33
*   **Instance Types:** `t3.medium`, `t3a.medium` (On-Demand).
*   **Key Addons:** AWS Load Balancer Controller, Nginx Ingress Controller.
*   **ArgoCD:** Installed via Helm, exposed via Ingress at `argocd.customer.com.br`.

### 3. EKS Worker Node (`worker-01`)
*   **Purpose:** Target cluster for application deployments.
*   **Kubernetes Version:** 1.33
*   **Compute:**
    *   **Managed Node Group:** `t3.medium`, `t3a.medium`.
    *   **Karpenter:** Configured for Spot instances (`t3`, `t3a` families) to handle `dev` workloads.
*   **Access:** Managed by ArgoCD from the Control Plane via IAM roles and EKS Pod Identity.

### 4. IAM & Security
*   **Pod Identity:** Used for mapping IAM roles to Kubernetes Service Accounts.
*   **Cross-Cluster Access:** The Control Plane assumes the `argo-deployer` role to manage resources in the Worker cluster.
*   **Backend:** Terraform state is securely stored in an S3 bucket with encryption and versioning.

## Project Structure

```text
.
├── argocd/                 # ArgoCD manifests (Applications, Projects, etc.)
├── helm/                   # Helm chart configurations
│   └── argocd/             # ArgoCD specific values
├── s3/                     # Terraform configuration for the S3 Backend
├── main.tf                 # Main Terraform configuration (VPC, EKS Modules)
├── providers.tf            # Provider configurations (AWS, Helm, Kubectl)
├── iam_argocd.tf           # IAM Roles and Policies for ArgoCD
├── helm_argocd.tf          # ArgoCD Helm Release configuration
├── secret_cluster_*.tf     # Secrets to register worker clusters in ArgoCD
├── locals.tf               # Local variables and project configuration
└── ...
```

## Prerequisites

*   Terraform >= 1.12
*   AWS CLI (configured with appropriate credentials)
*   `kubectl`
*   `helm`

## Getting Started

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

2.  **Review the Plan:**
    ```bash
    terraform plan
    ```

3.  **Apply Configuration:**
    ```bash
    terraform apply
    ```

4.  **Access ArgoCD:**
    *   URL: `https://argocd.customer.com.br` (Ensure DNS/Hosts entry is configured if this is a private/local test)
    *   The initial admin password is typically stored in a Kubernetes secret (check ArgoCD documentation or Helm values).

## S3 Backend

The Terraform state is stored in the `terraform-dev-tfstate-2025-12` S3 bucket. The configuration for creating this bucket is located in the `s3/` directory.

## GitOps Workflow

The `argocd/` directory contains the manifests for bootstrapping applications.
*   **Guestbook Example:** `argocd/applications/guestbook.yaml` deploys a sample app to the `worker-01` cluster.