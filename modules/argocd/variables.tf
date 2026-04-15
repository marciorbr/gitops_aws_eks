variable "project_name" {
  description = "Nome do Projeto"
}

variable "cluster_name_control_plane" {
  description = "Nome do cluster em que será instalado o recurso"
}

variable "cluster_names_workers" {
  description = "Nomes dos clusters em que serão instalados os recursos"
  type        = list(string)
}

# variable "helm_provide_cluster" {
#   description = "value"
# }