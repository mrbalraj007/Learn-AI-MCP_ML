###############################################################################
# terraform.tfvars  — copy this to terraform.tfvars and fill in your values
###############################################################################

aws_region       = "us-east-1"      # ← Change to your region
project_name     = "devtools-lab"
environment      = "dev"
instance_type    = "t3.medium"
root_volume_size = 30

# ⚠️  IMPORTANT: Replace with your actual IP for security
# To find your IP: curl -s https://checkip.amazonaws.com
allowed_ssh_cidr = ["0.0.0.0/0"]        # Replace with ["YOUR.IP/32"]

# Leave blank to use default VPC / auto-selected subnet
vpc_id    = ""
subnet_id = ""
