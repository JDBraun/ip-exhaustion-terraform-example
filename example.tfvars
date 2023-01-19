// Databricks Variables
databricks_account_username = ""
databricks_account_password = ""
databricks_account_id = ""
resource_owner = ""
resource_prefix = "ip-exhaustion-terraform-example"

// AWS Variables
aws_access_key = ""
aws_secret_key = ""
aws_account_id = ""
data_bucket = ""

// Dataplane Variables
region = "us-east-1"
routable_vpc_cidr_range = "10.0.0.0/25"
non_routable_vpc_cidr_range = "100.0.0.0/16"
routable_public_subnets_cidr = "10.0.0.96/28,10.0.0.112/28"
routable_private_subnets_cidr = "10.0.0.64/28,10.0.0.80/28"
non_routable_private_subnets_cidr = "100.0.0.0/17,100.0.128.0/17"
privatelink_subnets_cidr = "10.0.0.32/28,10.0.0.48/28"
availability_zones = "us-east-1a,us-east-1b"

// Regional Private Link Variables: https://docs.databricks.com/administration-guide/cloud-configurations/aws/privatelink.html#regional-endpoint-reference
relay_vpce_service = ""
workspace_vpce_service = ""
