export CLOUDFORMATION_STACK_NAME=chapter10

# Deploy the cloudformation stack to launch the EC2 instance
aws cloudformation deploy --template stack-nginx.yaml --capabilities CAPABILITY_AUTO_EXPAND --stack-name ${CLOUDFORMATION_STACK_NAME}

# Get the URL to connect to the ngxinx server running on the instance
APP_URL="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`Url`].OutputValue | [0]' --output text)"

# Print the URL
echo $APP_URL

# Use curl to access the URL
curl $APP_URL

# Edit line 43 of stack-nginx.yaml to update the string written to the sample web page to "Hello this World"
# Update the cloudformation stack
aws cloudformation deploy --template stack-nginx.yaml --capabilities CAPABILITY_AUTO_EXPAND --stack-name ${CLOUDFORMATION_STACK_NAME}

# Get and access the URL again
APP_URL="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`Url`].OutputValue | [0]' --output text)"
curl $APP_URL

# Now, update the stack again using the template in stack-nginx-with-update.yaml
aws cloudformation deploy --template stack-nginx-with-update.yaml --capabilities CAPABILITY_AUTO_EXPAND --stack-name ${CLOUDFORMATION_STACK_NAME}

# Get and access the URL again
APP_URL="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`Url`].OutputValue | [0]' --output text)"
curl $APP_URL

# Now change the message on line 60 in stack-nginx-with-update.yaml to "Hello my dear World" to test another update
# Update the stack
aws cloudformation deploy --template stack-nginx-with-update.yaml --capabilities CAPABILITY_AUTO_EXPAND --stack-name ${CLOUDFORMATION_STACK_NAME}

# Get and access the URL
APP_URL="$(aws cloudformation describe-stacks --stack-name ${CLOUDFORMATION_STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`Url`].OutputValue | [0]' --output text)"
curl $APP_URL

# Finally, delete the stack to remove the EC2 instance
aws cloudformation delete-stack --stack-name ${CLOUDFORMATION_STACK_NAME}
