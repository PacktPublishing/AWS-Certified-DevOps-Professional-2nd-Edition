export S3_BUCKET_NAME=devopspro-beyond-2
export AWS_REGION=eu-west-1
export CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX=chapter10/run-multiple-app-instances-using-asg-and-alb/templates
export CLOUDFORMATION_STACK_NAME=chapter10

# Render the CloudFormation templates with the correct location of the referenced templates
for template in vpc environment; do
  sed \
    --expression="s|<<AWS_REGION>>|${AWS_REGION}|g" \
    --expression="s|<<S3_BUCKET_NAME>>|${S3_BUCKET_NAME}|g" \
    --expression="s|<<CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX>>|${CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX}|g" \
    templates/${template}.yaml.tpl > templates/${template}.yaml
done

# Upload the cloudformation templates to s3
aws s3 sync templates s3://${S3_BUCKET_NAME}/${CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX}/

# Deploy the cloudformation stack to launch the EC2 instance
aws cloudformation deploy --template templates/environment.yaml --capabilities CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM --stack-name ${CLOUDFORMATION_STACK_NAME} --parameter-overrides NetworkCIDR=10.1.0.0/19

# Get the DNS name of the load balancer
LOAD_BALANCER_DNS="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue | [0]' --output text)"

# Use curl to access the first app (HelloApp)
curl --resolve "app1.dummyhostname.com:80:$(host ${LOAD_BALANCER_DNS} | head --lines 1 | cut -f4 -d' ')" http://app1.dummyhostname.com

# Use curl to access the second app (HiApp)
curl --resolve "app2.dummyhostname.com:80:$(host ${LOAD_BALANCER_DNS} | head --lines 1 | cut -f4 -d' ')" http://app2.dummyhostname.com

# Get the EC2 instance ID of one of the instances running the HelloApp application
INSTANCE_ID="$(aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running' 'Name=tag:aws:cloudformation:logical-id,Values=ASG' 'Name=tag:Name,Values=HelloApp' --query 'Reservations[0].Instances[0].InstanceId' --output text)"

# Connect to the instance using SSM
aws ssm start-session --target ${INSTANCE_ID}

# Get the hostname of the server to confirm.
hostname

# Check the status of the nginx service
systemctl status nginx

# Stop the nginx service to simulate a crashing application
sudo systemctl stop nginx

# Check the status of the nginx service again.
systemctl status nginx

# Disconnect from the instance
exit

# Use curl to access the HelloApp
curl --resolve "app1.dummyhostname.com:80:$(host ${LOAD_BALANCER_DNS} | head --lines 1 | cut -f4 -d' ')" http://app1.dummyhostname.com

# Delete the stack to remove the created resources
aws cloudformation delete-stack --stack-name ${CLOUDFORMATION_STACK_NAME}
