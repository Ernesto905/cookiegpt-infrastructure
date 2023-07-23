module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "~> 19.0"

    // Cluster details
    cluster_name    = "cookiegpt-cluster"
    cluster_version = "1.27"

    // Cluster is accessible from the internet
    cluster_endpoint_public_access  = true 

    // Specifies addons for our EKS Configuration
    cluster_addons = {
        // DNS server for the cluster
        coredns = {
            most_recent = true
        }
        // Maintains network rules on each EC2 node
        kube-proxy = {
            most_recent = true
        }
        // Elastic network interface on each EC2 node
        vpc-cni = {
            most_recent = true
        }
    }

    # Timeout settings
    cluster_addons_timeouts = {
        create = "60m"
        update = "30m"
        delete = "60m"
    }

    // Configure vpc networking upon which to run our cluster
    vpc_id                   = aws_vpc.cookiegpt-vpc.id
    subnet_ids               = [aws_subnet.cookiegpt-subnet-1.id, aws_subnet.cookiegpt-subnet-2.id]
    control_plane_subnet_ids = [aws_subnet.cookiegpt-subnet-1.id, aws_subnet.cookiegpt-subnet-2.id]

    # EKS Managed Node Group(s)
    eks_managed_node_group_defaults = {
        instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    }

    eks_managed_node_groups = {
        blue = {}
        green = {
        min_size     = 1
        max_size     = 10
        desired_size = 1

        instance_types = ["t3.large"]
        capacity_type  = "SPOT"
        }
    }

}


# provider "flux" {
#   kubernetes = {
#     config_path = "~/.kube/config"
#   }
#   git = {
#     url  = var.gitlab_url
#     http = {
#       username = var.gitlab_user
#       password = var.gitlab_token
#     }
#   }
# }

# resource "flux_bootstrap_git" "this" {
#   path                   = "clusters/my-cluster"
#   network_policy         = true
#   kustomization_override = file("${path.module}/kustomization.yaml")
# }


