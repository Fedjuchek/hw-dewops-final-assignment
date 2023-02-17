output "eks_vcp_private_subnet_ids" {
  value = tolist([aws_subnet.eks_vpc_subnet_private_a.id, aws_subnet.eks_vpc_subnet_private_b.id])
}

output "eks_vcp_public_subnet_ids" {
  value = tolist([aws_subnet.eks_vpc_subnet_public_a.id, aws_subnet.eks_vpc_subnet_public_b.id])
}

output "eks_vpc_id" {
  value = aws_vpc.hw_eks_vpc.id
}

output "eks_vpc_ciddr_block" {
  value = aws_vpc.hw_eks_vpc.cidr_block
}