resource "kubectl_manifest" "argo_clusters" {

  provider = kubectl.control_plane

  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: ${module.eks_worker_01.eks_cluster_name}
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: ${module.eks_worker_01.eks_cluster_name}
  config: |
    {
      "awsAuthConfig": {
        "clusterName": "${module.eks_worker_01.eks_cluster_name}",
        "roleARN": "${aws_iam_role.argo_deployer.arn}"
      },
      "tlsClientConfig": {
        "insecure": false,
        "caData": "${module.eks_worker_01.eks_certificate_authority}"
      }
    }
  server: "${module.eks_worker_01.eks_endpoint}"
YAML

  depends_on = [
    helm_release.argocd
  ]

}