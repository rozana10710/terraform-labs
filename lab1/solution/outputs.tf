output "server_name" {
  description = "The generated pet name"
  value       = random_pet.server.id
}
