module "eks-vpc" {
  source           = "./modules/eks-vpc"
  eks_cluster_name = var.eks_cluster_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.8.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = "1.24"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  vpc_id     = module.eks-vpc.eks_vpc_id
  subnet_ids = module.eks-vpc.eks_vcp_private_subnet_ids

  eks_managed_node_group_defaults = {
    create_node_security_group            = false
    attach_cluster_primary_security_group = true
    ami_type                              = "AL2_x86_64"
  }

  node_security_group_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = null
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 2
      desired_size = 2
    }
  }

  cluster_addons = {
    coredns = {
      preserve    = true
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "rds_sg"
  vpc_id = module.eks-vpc.eks_vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [module.eks-vpc.eks_vpc_ciddr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "hwrds"

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  db_name  = "hwrds"
  username = "admin"
  port     = "3306"

   # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  create_db_subnet_group = true
  subnet_ids             = module.eks-vpc.eks_vcp_private_subnet_ids
}
