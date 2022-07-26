1. providers: set of plugins that allows us talk to an API


STEPS:

1. create a vpc
2. create internet gateway
3. create custom route table
4. create a subnet
5. associate subnet with route table
6. create security group to allow port 22, 80, 443
7. create a network interface with an ip in the subnet that was create in step 4
8. Assign an elastic IP to the network interface in step 7
9. create ubuntu server and install/enable apache2