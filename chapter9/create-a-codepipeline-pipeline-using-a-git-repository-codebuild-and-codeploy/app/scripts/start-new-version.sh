cd /opt/codedeploy-agent/deployment-root/${DEPLOYMENT_GROUP_ID}/${DEPLOYMENT_ID}/deployment-archive
IMAGE_NAME=$(cat image-name.txt)

cat docker-login-password.txt | docker login --username AWS  --password-stdin $(echo ${IMAGE_NAME} | cut -f1 -d/)
echo Deploying ${IMAGE_NAME}...
docker run --detach --restart always --publish 80:8080 --name web-service ${IMAGE_NAME}
