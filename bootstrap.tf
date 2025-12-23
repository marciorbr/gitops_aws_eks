data "kubectl_filename_list" "manifests" {
  pattern = "./argocd/bootstrap/root.yaml"
}

resource "kubectl_manifest" "argo_root_bootstrap" {

  provider = kubectl.control_plane

  count     = length(data.kubectl_filename_list.manifests.matches)
  yaml_body = file(element(data.kubectl_filename_list.manifests.matches, count.index))

  depends_on = [
    helm_release.argocd
  ]

}