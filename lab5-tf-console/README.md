terraform console #opens an interactive prompt where you type an expression and Terraform shows the result immediately. Nothing is created in AWS.

> lower("Rosanna")
"rosanna"

> length(["logs", "data", "backup"])
3

> contains(["dev", "prod"], "test")
false

> merge({Owner = "rosanna"}, {Env = "dev"})
{
  "Env" = "dev"
  "Owner" = "rosanna"
}

> [for name in ["logs", "data"] : upper(name)] 
#Think of for as: “go through each item, do something to it, and give me back a new list.”
