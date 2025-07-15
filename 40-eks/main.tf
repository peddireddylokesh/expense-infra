resource "aws_key_pair" "eks" {
  key_name   = "expense-eks"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCm/jg5kmY2AILxpU9JHqh7ZZqrXTDmuhKrqpaO5bWB5CnOVvif8uQjtuMLuodQwMseZJXG0iK7Wp+nTEbD/9UHqvxoF21rvvDMlfdjbhlHvHurWujecSDTjrHN3kkfGV/Zc4FeeDVufNL38hiO2xOmPaKEJD+/4lUWM37DqVMySyJazY0lEbsWvK1U7CMerp01VFMlxbBkJx6t4PLw3Yf6h2rpN0GeP7FLMNgJBTPGQhfNUuU4NfTkeX4WccVs/rN5PMuJtsdhNhkHtZC7ooSv+kTz7FZz68SJfudux/txdWBCf7vPbU0lPMota/OxMY+jqXlYqddzRNDjPBK0wcUmJAxmQBI060rjiXGOoySRyYg1du/a+/KmBdcXfz8fhtEwctRd/kcMHBsK6IqUMvW2lHOU8XT+LXLZexvFTKhHd6diEbhgkVS4bNUomi2ZZ1bqvmc5tpQDpr0FH7GGx++20R5u48NPkPZycIj69tohoFpAkn0MbglFvoSZ+s5QnjR/W9BkLi/tqrzPKb2IRp4XJ1POtJbxfoDVHHXalzkktmPXgswHm2sJtiIe3++AxqI59WbNJWijaxQhZFUVewk7flVzwdcquZKzSz5vgj5sfRiyfc3x2RQYcHu2KfTqJO+q09o+115uiq0L0BhUAad69oJTKbEwiZowDkp3hHvbXQ== eks-key"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = "1.32" # later we upgrade 1.32
  create_node_security_group = false
  create_cluster_security_group = false
  cluster_security_group_id = local.eks_control_plane_sg_id
  node_security_group_id = local.eks_node_sg_id

  #bootstrap_self_managed_addons = false
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    metrics-server = {}
  }

  # Optional
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]


  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      #ami_type       = "AL2_x86_64"
      instance_types = ["m5.xlarge"]
      key_name = aws_key_pair.eks.key_name

      min_size     = 2
      max_size     = 10
      desired_size = 2
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEFSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        AmazonEKSLoadBalancingPolicy = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
        Name = local.name
    }
  )
}