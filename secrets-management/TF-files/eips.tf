# Resource: aws_eip
resource "aws_eip" "nat1" {
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "nat2" {
  depends_on = [aws_internet_gateway.igw]
}