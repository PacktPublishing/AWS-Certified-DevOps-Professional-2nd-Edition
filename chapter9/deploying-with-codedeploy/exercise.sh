export S3_BUCKET_NAME=devopspro-beyond-2
export AWS_REGION=eu-west-1
export INFRA_CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX=chapter9/deploying-with-codedeploy/infra
export CLOUDFORMATION_STACK_NAME=webservers
export APPLICATION_NAME=hello-web
export DEPLOYMENT_GROUP_NAME=nginx-servers
export DEPLOYMENT_REVISION_NAME=revision.zip
export DEPLOYMENT_S3_BUCKET_KEY=chapter9/deploying-with-codedeploy/app/${DEPLOYMENT_REVISION_NAME}

# Upload the cloudformation templates to s3
aws s3 sync infra s3://${S3_BUCKET_NAME}/${INFRA_CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX}/

# Use cloudformation to create the infrastructure
aws cloudformation deploy --template infra/nested-stacks-root-nginx-dev.yaml --capabilities CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM --stack-name ${CLOUDFORMATION_STACK_NAME} --parameter-overrides NetworkCIDR=10.1.0.0/19 S3Bucket=${S3_BUCKET_NAME}

Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - webservers

# This sets up only the dev environment. View the URL of the loadbalancer for dev environment:
aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`DevUrl`].OutputValue | [0]' --output text

# Create the CodeDeploy application:
aws deploy create-application --compute-platform Server --application-name ${APPLICATION_NAME}

CODEDEPLOY_SERVICE_ROLE_ARN="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`CodeDeployServiceRole`].OutputValue | [0]' --output text)"
NGINX_SERVERS_ASG="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`NginxAsg`].OutputValue | [0]' --output text)"

# Create the deployment group for the application
aws deploy create-deployment-group --service-role-arn ${CODEDEPLOY_SERVICE_ROLE_ARN} --auto-scaling-groups ${NGINX_SERVERS_ASG} --deployment-config-name CodeDeployDefault.OneAtATime --application-name ${APPLICATION_NAME} --deployment-group-name ${DEPLOYMENT_GROUP_NAME}

# Package the revision
pushd app && zip --recurse-paths ../${DEPLOYMENT_REVISION_NAME} * && popd
aws s3 cp ${DEPLOYMENT_REVISION_NAME} s3://${S3_BUCKET_NAME}/${DEPLOYMENT_S3_BUCKET_KEY}


# Get the details of the deployment
DEPLOYMENT_ID="$(aws deploy create-deployment --description v1.0.0 --deployment-group-name ${DEPLOYMENT_GROUP_NAME} --application-name ${APPLICATION_NAME} --revision "revisionType=S3,s3Location={bucket=${S3_BUCKET_NAME},key=${DEPLOYMENT_S3_BUCKET_KEY},bundleType=zip}" --query deploymentId --output text)"
aws deploy get-deployment --deployment-id ${DEPLOYMENT_ID}

# You can also view this on the AWS console

aws deploy delete-deployment-group --deployment-group-name ${DEPLOYMENT_GROUP_NAME} --application-name ${APPLICATION_NAME}

aws cloudformation delete-stack --stack-name ${CLOUDFORMATION_STACK_NAME}
