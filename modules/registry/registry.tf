resource "yandex_container_registry" "my-registry" {
  name      = "my-registry"
  folder_id = var.folder_id
}

resource "yandex_container_repository" "my-repository" {
  name = "${yandex_container_registry.my-registry.id}/my-repository"
  provisioner "local-exec" {
    when    = destroy
    command = <<-CMD
    IMAGES=$(yc container image list --format json | jq -r '.[].id')
    if [ ! -z "$IMAGES" ]; then
      for IMAGE in $IMAGES; do
        yc container image delete --id $IMAGE
      done
    else
      echo "No images found."
    fi
    CMD
  }
}

resource "null_resource" "docker_login" {
  provisioner "local-exec" {
    command = "yc container registry configure-docker"
  }
}

