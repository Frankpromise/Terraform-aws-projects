# configure a docker provider
provider "docker" {}
 # image to be used for the docker container

resource "docker_image" "centos" {
  name = "centos:7"
  keep_locally = true
}

# create a container
resource "docker_container" "centos" {
  image = docker_image.centos.latest
  name = "centos"
  start = true
  command = ["/bin/sleep", "500"]
}
