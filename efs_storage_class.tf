resource "kubectl_manifest" "dynamic_efs_storage_class" {

  provider = kubectl.control_plane

  yaml_body = <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: dynamic-efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${aws_efs_file_system.dynamic.id}
  subPathPattern: "$${.PVC.name}"
  directoryPerms: "777"
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
YAML

  depends_on = [
    module.eks_control_plane,
  ]
}