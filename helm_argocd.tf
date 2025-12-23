resource "helm_release" "argocd" {

  provider = helm.control_plane

  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.1.5"
  values     = [file("helm/argocd/values.yaml")]

  depends_on = [module.eks_control_plane]

}