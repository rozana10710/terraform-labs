# Values for this lab. Safe to commit: there are NO secrets in here.
# The secret is read from SSM Parameter Store instead (see main.tf).

owner       = "rosanna" # <-- change to your own first name
environment = "dev"

buckets = {
  logs    = "Application logs"
  uploads = "User uploads"
  backup  = "Backups"
}
