output value {
    value = {
        id = aws_vpc.vpc.id
        public_subnets = {
            for i,v in aws_subnet.publics:
                v.availability_zone => v.id
        }
    }
}