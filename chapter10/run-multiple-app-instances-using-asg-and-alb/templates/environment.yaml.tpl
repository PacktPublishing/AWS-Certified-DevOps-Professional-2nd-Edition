Description: This template creates AWS resources needed to run nginx instances for an environment

Transform: AWS::LanguageExtensions

Parameters:
  NetworkCIDR:
    Description: The CIDR block for the environment's VPC
    Type: String
    AllowedPattern: '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$'
  MinInstances:
    Description: Minimum number of nginx instances to run
    Type: Number
    MinValue: 2
    Default: 2
  MaxInstances:
    Description: Maximum number of nginx instances to run
    Type: Number
    MinValue: 2
    Default: 3

Resources:
  IAMRole:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://<<S3_BUCKET_NAME>>.s3.<<AWS_REGION>>.amazonaws.com/<<CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX>>/iam.yaml
  Network:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://<<S3_BUCKET_NAME>>.s3.<<AWS_REGION>>.amazonaws.com/<<CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX>>/vpc.yaml
      Parameters:
        Name:
          Ref: AWS::StackName
        CIDR:
          Ref: NetworkCIDR
  LoadBalancer:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://<<S3_BUCKET_NAME>>.s3.<<AWS_REGION>>.amazonaws.com/<<CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX>>/loadbalancer.yaml
      Parameters:
        Name:
          Ref: AWS::StackName
        VpcId:
          Fn::GetAtt:
          - Network
          - Outputs.VpcId
        SubnetIds:
          Fn::Join:
          - ','
          - - Fn::GetAtt:
              - Network
              - Outputs.SubnetIDPublica
            - Fn::GetAtt:
              - Network
              - Outputs.SubnetIDPublicb
            - Fn::GetAtt:
              - Network
              - Outputs.SubnetIDPublicc
        TargetGroupArnApp1:
          Fn::GetAtt:
          - App1
          - Outputs.TargetGroupArn
        TargetGroupArnApp2:
          Fn::GetAtt:
          - App2
          - Outputs.TargetGroupArn
  App1:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://<<S3_BUCKET_NAME>>.s3.<<AWS_REGION>>.amazonaws.com/<<CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX>>/app.yaml
      Parameters:
        Name: HelloApp
        VpcId:
          Fn::GetAtt:
          - Network
          - Outputs.VpcId
        SubnetIds:
          Fn::Join:
          - ','
          - - Fn::GetAtt:
              - Network
              - Outputs.SubnetIDPrivatea
            - Fn::GetAtt:
              - Network
              - Outputs.SubnetIDPrivateb
            - Fn::GetAtt:
              - Network
              - Outputs.SubnetIDPrivatec
        MinInstances:
          Ref: MinInstances
        MaxInstances:
          Ref: MaxInstances
        InstanceProfileArn:
          Fn::GetAtt:
          - IAMRole
          - Outputs.EC2InstanceProfileArn
  App2:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://<<S3_BUCKET_NAME>>.s3.<<AWS_REGION>>.amazonaws.com/<<CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX>>/app.yaml
      Parameters:
        Name: HiApp
        VpcId:
          Fn::GetAtt:
          - Network
          - Outputs.VpcId
        SubnetIds:
          Fn::Join:
          - ','
          - - Fn::GetAtt:
              - Network
              - Outputs.SubnetIDPrivatea
            - Fn::GetAtt:
              - Network
              - Outputs.SubnetIDPrivateb
            - Fn::GetAtt:
              - Network
              - Outputs.SubnetIDPrivatec
        MinInstances:
          Ref: MinInstances
        MaxInstances:
          Ref: MaxInstances
        InstanceProfileArn:
          Fn::GetAtt:
          - IAMRole
          - Outputs.EC2InstanceProfileArn

Outputs:
  LoadBalancerDNS:
    Description: The DNS entry that can be used to reach the load balancer for the environment
    Value:
      Fn::GetAtt:
      - LoadBalancer
      - Outputs.DNSName
