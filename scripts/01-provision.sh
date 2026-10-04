#!/usr/bin/env bash
# Create the VPC, subnet, internet gateway, route table, security group,
# key pair and four Debian 12 instances. Based on Slawek Zachcial's AWS guide,
# with t3.small/20 GB instances, SSH limited to your IP, a pod-CIDR rule and
# source/destination check disabled for pod routing.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

if [ "$(vpc_id)" != "None" ]; then
  echo "A VPC tagged ${TAG} already exists in ${AWS_REGION}. Run scripts/cleanup.sh first." >&2
  exit 1
fi

aws sts get-caller-identity --query 'Account' --output text >/dev/null
MY_IP="$(curl -s https://checkip.amazonaws.com)/32"
echo "Region: ${AWS_REGION}  Profile: ${AWS_PROFILE}  SSH allowed from: ${MY_IP}"

echo "== Networking"
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.240.0.0/24 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${TAG}}]" \
  --output text --query 'Vpc.VpcId')

SUBNET_ID=$(aws ec2 create-subnet --vpc-id "${VPC_ID}" --cidr-block 10.240.0.0/24 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${TAG}}]" \
  --output text --query 'Subnet.SubnetId')

IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${TAG}}]" \
  --output text --query 'InternetGateway.InternetGatewayId')
aws ec2 attach-internet-gateway --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}"

RT_ID=$(aws ec2 create-route-table --vpc-id "${VPC_ID}" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${TAG}}]" \
  --output text --query 'RouteTable.RouteTableId')
aws ec2 associate-route-table --route-table-id "${RT_ID}" --subnet-id "${SUBNET_ID}" >/dev/null
aws ec2 create-route --route-table-id "${RT_ID}" --destination-cidr-block 0.0.0.0/0 --gateway-id "${IGW_ID}" >/dev/null

SG_ID=$(aws ec2 create-security-group --group-name "${TAG}" \
  --description "Kubernetes The Hard Way security group" --vpc-id "${VPC_ID}" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${TAG}}]" \
  --output text --query 'GroupId')
aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" --protocol all --cidr 10.240.0.0/24 >/dev/null
aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" --protocol all --cidr 10.200.0.0/16 >/dev/null
aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" --protocol tcp --port 22 --cidr "${MY_IP}" >/dev/null

echo "== Key pair"
if [ -e "${KEY_FILE}" ]; then
  echo "${KEY_FILE} already exists; refusing to overwrite it." >&2
  exit 1
fi
aws ec2 create-key-pair --key-name "${TAG}" --output text --query 'KeyMaterial' > "${KEY_FILE}"
chmod 600 "${KEY_FILE}"

echo "== Instances"
IMAGE_ID=$(aws ec2 describe-images --owners 136693071363 \
  --filters 'Name=root-device-type,Values=ebs' 'Name=architecture,Values=x86_64' 'Name=name,Values=debian-12-amd64-*' \
  --output text --query 'sort_by(Images[],&Name)[-1].ImageId')
ROOT_DEVICE=$(aws ec2 describe-images --image-ids "${IMAGE_ID}" --output text --query 'Images[0].RootDeviceName')
echo "Debian 12 AMI: ${IMAGE_ID}"

IDS=()
for NAME in jumpbox server node-0 node-1; do
  if [ "${NAME}" = "jumpbox" ]; then TYPE=t3.micro; DISK=10; else TYPE=t3.small; DISK=20; fi
  ID=$(aws ec2 run-instances \
    --associate-public-ip-address \
    --image-id "${IMAGE_ID}" --count 1 \
    --key-name "${TAG}" \
    --security-group-ids "${SG_ID}" \
    --instance-type "${TYPE}" \
    --credit-specification CpuCredits=standard \
    --block-device-mappings "DeviceName=${ROOT_DEVICE},Ebs={VolumeSize=${DISK},VolumeType=gp3}" \
    --subnet-id "${SUBNET_ID}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${NAME}},{Key=Project,Value=${TAG}}]" \
    --output text --query 'Instances[].InstanceId')
  IDS+=("${ID}")
  echo "${NAME}: ${ID} (${TYPE}, ${DISK} GB)"
done
aws ec2 wait instance-running --instance-ids "${IDS[@]}"

echo "== Disabling source/destination check on server, node-0, node-1"
for NAME in server node-0 node-1; do
  aws ec2 modify-instance-attribute --instance-id "$(instance_id "${NAME}")" --no-source-dest-check
done

aws ec2 describe-instances --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'sort_by(Reservations[].Instances[],&PrivateIpAddress)[].{a_NAME:Tags[?Key==`Name`].Value | [0],b_TYPE:InstanceType,c_PRIVATE:PrivateIpAddress,d_PUBLIC:PublicIpAddress,e_STATE:State.Name}' \
  --output table

echo "Done. Wait a minute for SSH to come up, then run scripts/02-prepare-hosts.sh"
