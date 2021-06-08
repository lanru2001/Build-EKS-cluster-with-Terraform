#Create an Amazon EKS Cluster with Managed Node Group using Terraform

#VPC 
resource "aws_vpc" "eks_vpc" {
  cidr_block              = var.vpc_cidr 
  enable_dns_support      = true
  enable_dns_hostnames    = true

  tags       = {
    Name     = "${local.environment_prefix}-dev-vpc"
  }
}

#Private subnets
resource "aws_subnet" "eks_private_subnets" {
  count                   = var.create ? 2:0 
  vpc_id                  = aws_vpc.eks_vpc.id
  availability_zone       = var.azs[count.index]  
  cidr_block              = var.private_subnets_cidr[count.index]   

  tags    = {
    Name  = "eks-private-subnet-${count.index +1}"
  }
}

#Pubic subnets
resource "aws_subnet" "eks_public_subnets" {
  count                    = var.create ? 2:0 
  vpc_id                   = aws_vpc.eks_vpc.id
  availability_zone        = var.azs[count.index]    
  map_public_ip_on_launch  = true
  cidr_block               = var.public_subnets_cidr[count.index]   

  tags     = {
    Name   = "eks-public-subnet-${count.index +1}"
  }
}

#IGW
resource "aws_internet_gateway" "eks_igw" {
  vpc_id     = aws_vpc.eks_vpc.id

  tags       = {
    Name   = "${local.environment_prefix}-igw"
  }
}

#Route table for public subnet
resource "aws_route_table" "eks_public_rtable" {
  count                     = var.create ? 2:0 
  vpc_id                    = aws_vpc.eks_vpc.id

  route {
    cidr_block              = "0.0.0.0/0"
    gateway_id              = aws_internet_gateway.eks_igw.id
  }

  tags    = {
    Name  = "${local.environment_prefix }-prtable-${count.index + 1}"
  }

  depends_on = [ aws_internet_gateway.eks_igw ]
}

#Route table for private subnet
resource "aws_route_table" "eks_private_rtable" {
  count                     = var.create ? 2:0 
  vpc_id                    = aws_vpc.eks_vpc.id

  #route {
  #  cidr_block              = "0.0.0.0/0"
  #  gateway_id              = aws_internet_gateway.eks_igw.id
  #}

  tags    = {
    Name  = "${local.environment_prefix }-pvrtable-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.eks_igw]
}

#Assign the route table to public subnets
resource "aws_route_table_association" "public-subnet-association" {
  count                     = var.create ? 2:0 
  subnet_id                 = aws_subnet.eks_public_subnets[count.index].id
  route_table_id            = aws_route_table.eks_public_rtable[count.index].id
}

#Assign the route table to private subnets
resource "aws_route_table_association" "private-subnet-association" {
  count                     = var.create ? 2:0 
  subnet_id                 = aws_subnet.eks_private_subnets[count.index].id
  route_table_id            = aws_route_table.eks_private_rtable[count.index].id
}

# Public route 
resource "aws_route" "public_route" {
  count                     = var.create ? 2:0 
  route_table_id            = aws_route_table.eks_public_rtable[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                =  aws_internet_gateway.eks_igw.id 
}

# private route 
resource "aws_route" "private_route" {
  count                     = var.create ? 2:0 
  route_table_id            = aws_route_table.eks_private_rtable[count.index].id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.eks_nat_gw.id
}

# EIP 
resource "aws_eip" "eks_eip" {
   vpc                       = true 
   #associate_with_private_ip = "10.0.0.5"
   depends_on                 = [aws_internet_gateway.eks_igw]

}

# NAT Gateway
resource "aws_nat_gateway" "eks_nat_gw" {
  allocation_id             = aws_eip.eks_eip.id
  subnet_id                 = aws_subnet.eks_public_subnets[count.index].id
  depends_on                = [ aws_internet_gateway.eks_igw ]

  tags = {
    Name =  "${local.module_prefix}-nat-gateway"
  }
}

# Security group 
resource "aws_security_group" "endpoint_security_group" {
  name                      = "${local.module_prefix}-sg"
  vpc_id                    = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }
  
   ingress {
    protocol    = "tcp"
    from_port   = 3306
    to_port     = 3306
    cidr_blocks = ["0.0.0.0/0"]
  }  
  
    ingress {
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = ["0.0.0.0/0"]
  }  
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    =  -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [
      aws_vpc.eks_vpc   
  ]
}

resource "aws_network_interface"  "eks_interface" {
  count                 = var.create ? 2:0 
  subnet_id             = var.eks_public_subnets[count.index].id 
  tags =  {

    Name = var.name
  }

}


# AWS vpc endpoint
resource "aws_vpc_endpoint" "eks_dkr" {
  vpc_id       = "${aws_vpc.eks_vpc.id}"
  service_name = "com.amazonaws.${var.region}.eks.dkr"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  subnet_ids          = [ aws_subnet.eks_private_subnet[count.index].id , aws_subnet.eks_public_subnet[count.index].id ]
  security_group_ids = [aws_security_group.endpoint_security_group.id]
  tags = {
    Name = "endpoint-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "eks_api" {
  vpc_id       = "${aws_vpc.eks_vpc.id}"
  service_name = "com.amazonaws.${var.region}.eks.api"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.eks_private_subnet[count.index].id , aws_subnet.eks_public_subnet[count.index].id ]
  security_group_ids = [aws_security_group.endpoint_security_group.id]
  tags = {
    Name = "vpc-endpoint-${var.environment}"
    Environment = var.environment
  }
}



# S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.eks_vpc.id}"
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [ aws_route_table.eks_private_rtable[count.index].id ]     ]
  tags = {
    Name = "S3 VPC Endpoint Gateway - ${var.environment}"
    Environment = var.environment
  }
}

#EKS Cluster
resource "aws_eks_cluster" "eks_uclib" {
  name     = var.eks_cluster_name
  role_arn = "${aws_iam_role.eks_cluster.arn}"
  version  = var.eks_version
  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id, aws_security_group.eks_nodes.id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    subnet_ids = var.eks_cluster_subnet_ids
  }
 # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  
  depends_on = [
    "aws_iam_role_policy_attachment.aws_eks_cluster_policy",
    "aws_iam_role_policy_attachment.aws_eks_service_policy"
  ]
}

#EKS Cluster security group
resource "aws_security_group" "eks_cluster" {
  name        = var.cluster_sg_name
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id
  tags = {
    Name = var.cluster_sg_name
  }
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}
resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "egress"
}


#EKS Worker Node Group Security Group
resource "aws_security_group" "eks_nodes" {
  name        = var.name 
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name                                            = var.nodes_sg_name
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}
resource "aws_security_group_rule" "nodes" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "ingress"
}
resource "aws_security_group_rule" "nodes_inbound" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  to_port                  = 65535
  type                     = "ingress"
}


#Worker Node Groups for Public & Private Subnets
# Deploy some nodes in the public and private subnets and use a single vpc endpoint to enable communication without needing NAT gateway for nodes in 
#private subnet to communicate with the ones in public subnet
# Nodes in private subnets
resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.scholar.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids
  ami_type        = var.ami_type
  disk_size       = var.disk_size
  instance_types  = var.instance_types
  scaling_config {
    desired_size = var.pvt_desired_size
    max_size     = var.pvt_max_size
    min_size     = var.pvt_min_size
  }
  tags = {
    Name = var.node_group_name
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_worker_node_policy,
    aws_iam_role_policy_attachment.aws_eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_read_only,
  ]
}

# Nodes in public subnet
resource "aws_eks_node_group" "public" {
  cluster_name     = aws_eks_cluster.main.name
  node_group_name  = "${var.node_group_name}-public"
  node_role_arn    = aws_iam_role.eks_nodes.arn
  subnet_ids       = var.public_subnet_ids
  ami_type         = var.ami_type
  disk_size        = var.disk_size
  instance_types   = var.instance_types
  scaling_config {
    desired_size   = var.pblc_desired_size
    max_size       = var.pblc_max_size
    min_size       = var.pblc_min_size
  }
  tags = {
    Name = "${var.node_group_name}-public"
  }
# Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_worker_node_policy,
    aws_iam_role_policy_attachment.aws_eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_read_only,
  ]
}

resource "aws_cloudwatch_log_group" "scholar" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  name              = "eks/${var.cluster_name}/cluster"
  retention_in_days = 7

}


#EC2 Launch configuration 
resource "aws_launch_configuration" "worker" {
  iam_instance_profile = "${aws_iam_instance_profile.worker-node.name}"
  image_id             = ""
  instance_type        = ""
  name_prefix          = "worker-node"
  security_groups      = ["${aws_security_group.worker-node-sg.id}"]
  user_data            = "${file(launch_config.sh))}"

  lifecycle {
    create_before_destroy = true
  }
}

#Use for fargate launch type
#resource "aws_eks_fargate_profile" "example" {
#  cluster_name           = aws_eks_cluster.scholar.name
#  fargate_profile_name   = "scholar"
#  pod_execution_role_arn = aws_iam_role.scholar.arn
#  subnet_ids             = aws_subnet.scholar[*].id
#
#  selector {
#    namespace = "Dev"
#  }
#}
