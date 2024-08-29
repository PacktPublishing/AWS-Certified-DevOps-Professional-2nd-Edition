INSTANCE_ID="$(aws ec2 run-instances \
  --region us-east-1 \
  --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64 \
  --instance-type t4g.nano \
  --query 'Instances[0].InstanceId' \
  --output text)"

IMAGE_ID="$(aws ec2 create-image \
  --region us-east-1 \
  --instance-id ${INSTANCE_ID} \
  --name "DevOps_Chapter2" \
  --query 'ImageId' \
  --output text)"

aws ec2 describe-images \
  --region us-east-1 \
  --image-ids ${IMAGE_ID} \
  --query 'Images[0].State' \
  --output text

INSTANCE2_ID="$(aws ec2 run-instances \
  --region us-east-1 \
  --image-id ${IMAGE_ID} \
  --instance-type t4g.nano \
  --query 'Instances[0].InstanceId' \
  --output text)"

aws ec2 terminate-instances \
  --region us-east-1 \
  --instance-ids "${INSTANCE_ID}" "${INSTANCE2_ID}"

AMI_SNAPSHOT_ID="$(aws ec2 describe-images \
  --region us-east-1 \
  --image-ids ${IMAGE_ID} \
  --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId' \
  --output text)"

aws ec2 deregister-image \
  --region us-east-1 \
  --image-id ${IMAGE_ID}

aws ec2 delete-snapshot \
  --region us-east-1 \
  --snapshot-id ${AMI_SNAPSHOT_ID}
