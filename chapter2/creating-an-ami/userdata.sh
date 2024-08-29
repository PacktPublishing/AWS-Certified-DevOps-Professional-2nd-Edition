# Using instance user data scripts to configure EC2 instances at launch
read -r -d '' SCRIPT << EOF
#!/bin/bash
date > /myfile.txt
cat /myfile.txt
EOF

aws ec2 run-instances \
  --region us-east-1 \
  --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64 \
  --instance-type t4g.nano \
  --user-data "${SCRIPT}"
