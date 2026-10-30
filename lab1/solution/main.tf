resource "random_pet" "server" {
  length    = 2
  separator = "-"
}

resource "local_file" "motd" {
  filename = "${path.module}/motd.txt"
  content  = "Welcome to ${random_pet.server.id}"
}
