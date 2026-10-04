# Lab 13: Cleanup

Kelsey's lab just says to delete the machines. On AWS, run [`scripts/cleanup.sh`](../scripts/cleanup.sh). It looks up every resource by tag, so it works in a fresh terminal, and deletes instances, disks, the key pair, the security group, the route table, the internet gateway, the subnet and the VPC.

To pause instead: [`scripts/stop.sh`](../scripts/stop.sh) keeps everything for about $0.20/day, and [`scripts/start.sh`](../scripts/start.sh) brings it back.

Check Billing in the AWS console the next day to confirm EC2 charges have stopped.
