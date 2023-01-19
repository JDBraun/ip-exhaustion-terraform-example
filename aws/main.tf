locals {
  account_id                          = var.aws_account_id
  prefix                              = var.resource_prefix
  owner                               = var.resource_owner
  routable_vpc_cidr_range             = var.routable_vpc_cidr_range
  non_routable_vpc_cidr_range         = var.non_routable_vpc_cidr_range
  routable_public_subnets_cidr        = split(",", var.routable_public_subnets_cidr)  
  routable_private_subnets_cidr       = split(",", var.routable_private_subnets_cidr)
  non_routable_private_subnets_cidr   = split(",", var.non_routable_private_subnets_cidr)
  privatelink_subnets_cidr            = split(",", var.privatelink_subnets_cidr)
  sg_egress_ports                     = [443, 3306, 6666]
  sg_ingress_protocol                 = ["tcp", "udp"]
  sg_egress_protocol                  = ["tcp", "udp"]
  availability_zones                  = split(",", var.availability_zones)
  dbfsname                            = join("", [local.prefix, "-", var.region, "-", "dbfsroot"]) 
}

// Create External Databricks Workspace
module "databricks_mws_workspace" {
  source = "./modules/databricks_workspace"
  providers = {
    databricks = databricks.mws
  }

  databricks_account_id        = var.databricks_account_id
  resource_prefix              = local.prefix
  security_group_ids           = [aws_security_group.sg.id]
  subnet_ids                   = aws_subnet.non_routable[*].id
  vpc_id                       = aws_vpc.dataplane_vpc.id
  cross_account_role_arn       = aws_iam_role.cross_account_role.arn
  bucket_name                  = aws_s3_bucket.root_storage_bucket.id
  region                       = var.region
  backend_rest                 = aws_vpc_endpoint.backend_rest.id
  backend_relay                = aws_vpc_endpoint.backend_relay.id
}

// Create Create Cluster & Instance Profile
module "cluster_configuration" {
    source = "./modules/cluster_configuration"
    providers = {
      databricks = databricks.created_workspace
    }
  
  instance_profile = aws_iam_instance_profile.s3_instance_profile.arn
  depends_on = [module.databricks_mws_workspace]
}