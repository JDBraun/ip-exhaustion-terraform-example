# Workspace Deployment into Non-Routable Subnet Space

- This example is meant to be an example to assist with trials, proof of concepts, and a foundation for production deployments. 
- There are no guarantees or warranties associated with this example.

# Terraform Script

- **Data Plane Creation:**
    - Workspace Subnets
    - Security Groups
    - NACLs
    - Route Tables
    - Internet Gateway
    - Private & Public NAT Gateway
    - AWS VPC Endpoints (S3, Kinesis, STS, Databricks Endpoints)
    - S3 Root Bucket
    - Cross Account - IAM Role
    - S3 Instance Profile - IAM Role

- **Workspace Deployment:**
    - Credential Configuration
    - Storage Configuration
    - Network Configuration (Backend PrivateLink Enabled)

- **Post Workspace Deployment:**
    - Data Engineering Cluster 
    - Instance Profile Registration

# Getting Started

1. Clone this Repo 

2. Install [Terraform](https://developer.hashicorp.com/terraform/downloads)

3. Fill out `example.tfvars` and place in `aws` directory

5. CD into `aws`

5. Run `terraform init`

6. Run `terraform validate`

7. From `aws` directory, run `terraform plan -var-file ../example.tfvars`

8. Run `terraform apply -var-file ../example.tfvars`


# Network Diagram

![Architecture Diagram](https://github.com/JDBraun/ip-exhaustion-terraform-example/blob/master/img/IP%20Exhaustion%20-%20Network%20Topology.png)
