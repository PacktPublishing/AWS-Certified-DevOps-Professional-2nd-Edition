Description: |
  This template creates a VPC with one public subnet and one private subnets in AZs a, b and c.
  It also creates the NAT instances and required routes to enable outbound access to the internet

Transform: AWS::LanguageExtensions

Parameters:
  Name:
    Description: The name of the VPC to create
    Type: String
    AllowedPattern: '[a-z0-9]{3,}'
  CIDR:
    Description: The CIDR block for the VPC
    Type: String
    AllowedPattern: '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$'

Mappings:
  AZs:
    indexes:
      a: '0'
      b: '1'
      c: '2'

Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock:
        Ref: CIDR
      EnableDnsSupport: 'true'
      EnableDnsHostnames: 'true'
      Tags:
      - Key: Name
        Value:
          Ref: Name
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
      - Key: Name
        Value:
          Ref: Name
  InternetGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId:
        Ref: InternetGateway
      VpcId:
        Ref: VPC
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId:
        Ref: VPC
      Tags:
      - Key: Name
        Value:
          Fn::Sub: ${Name}-public-${AWS::Region}
  PublicDefaultRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId:
        Ref: PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId:
        Ref: InternetGateway
  Fn::ForEach::Subnets:
  - Az
  - ['a', 'b', 'c']
  - 'PublicSubnet${Az}':
      Type: AWS::EC2::Subnet
      Properties:
        VpcId:
          Ref: VPC
        CidrBlock:
          Fn::Select:
          - Fn::FindInMap:
            - AZs
            - indexes
            - Ref: Az
          - Fn::Cidr:
            - Fn::Select:
              - 0
              - Fn::Cidr:
                - Ref: CIDR
                - 4
                - 10
            - 4
            - 8
        AvailabilityZone:
          Fn::Sub: ${AWS::Region}${Az}
        MapPublicIpOnLaunch: 'true'
        Tags:
        - Key: Name
          Value:
            Fn::Sub: ${Name}-public-${AWS::Region}${Az}
    'PrivateSubnet${Az}':
      Type: AWS::EC2::Subnet
      Properties:
        VpcId:
          Ref: VPC
        CidrBlock:
          Fn::Select:
          - Fn::FindInMap:
            - AZs
            - indexes
            - Ref: Az
          - Fn::Cidr:
            - Fn::Select:
              - 1
              - Fn::Cidr:
                - Ref: CIDR
                - 4
                - 10
            - 4
            - 8
        AvailabilityZone:
          Fn::Sub: ${AWS::Region}${Az}
        Tags:
        - Key: Name
          Value:
            Fn::Sub: ${Name}-private-${AWS::Region}${Az}
    'PrivateRouteTable${Az}':
      Type: AWS::EC2::RouteTable
      Properties:
        VpcId:
          Ref: VPC
        Tags:
        - Key: Name
          Value:
            Fn::Sub: ${Name}-private-${AWS::Region}${Az}
    'PublicRouteTableAssociation${Az}':
      Type: AWS::EC2::SubnetRouteTableAssociation
      Properties:
        RouteTableId:
          Ref:
            Fn::Sub: PublicRouteTable
        SubnetId:
          Ref:
            Fn::Sub: PublicSubnet${Az}
    'PrivateRouteTableAssociation${Az}':
      Type: AWS::EC2::SubnetRouteTableAssociation
      Properties:
        RouteTableId:
          Ref:
            Fn::Sub: PrivateRouteTable${Az}
        SubnetId:
          Ref:
            Fn::Sub: PrivateSubnet${Az}
  Fn::ForEach::NAT:
  - Az
  - ['a', 'b', 'c']
  - 'NAT${Az}':
      Type: AWS::CloudFormation::Stack
      Properties:
        # Using NAT instances instead of a NAT gateway for the sake of cost
        TemplateURL: https://<<S3_BUCKET_NAME>>.s3.<<AWS_REGION>>.amazonaws.com/<<CLOUDFORMATION_TEMPLATES_S3_BUCKET_PREFIX>>/nat-instance.yaml
        Parameters:
          VpcId:
            Ref: VPC
          SubnetId:
            Ref:
              Fn::Sub: 'PublicSubnet${Az}'
          SubnetAz:
            Fn::Sub: ${AWS::Region}${Az}
          RouteTableIds:
            Ref:
              Fn::Sub: 'PrivateRouteTable${Az}'
          SubnetCidrs:
            Fn::GetAtt:
            - Fn::Sub: PrivateSubnet${Az}
            - CidrBlock

Outputs:
  VpcId:
    Description: The ID of the created VPC
    Value:
      Ref: VPC
  Fn::ForEach::SubnetIDs:
  - Az
  - ['a', 'b', 'c']
  - 'SubnetIDPublic${Az}':
      Description:
        Fn::Sub: The ID of the Public subnet in ${AWS::Region}${Az}
      Value:
        Ref:
          Fn::Sub: 'PublicSubnet${Az}'
    'SubnetIDPrivate${Az}':
      Description:
        Fn::Sub: The ID of the private subnet in ${AWS::Region}${Az}
      Value:
        Ref:
          Fn::Sub: PrivateSubnet${Az}
  Fn::ForEach::SubnetCIDRs:
  - Az
  - ['a', 'b', 'c']
  - 'SubnetCIDRPublic${Az}':
      Description:
        Fn::Sub: The CIDR of the Public subnet in ${AWS::Region}${Az}
      Value:
        Fn::GetAtt:
        - Fn::Sub: 'PublicSubnet${Az}'
        - CidrBlock
    'SubnetCIDRPrivate${Az}':
      Description:
        Fn::Sub: The CIDR of the private subnet in ${AWS::Region}${Az}
      Value:
        Fn::GetAtt:
        - Fn::Sub: PrivateSubnet${Az}
        - CidrBlock
  Fn::ForEach::SubnetNames:
  - Az
  - ['a', 'b', 'c']
  - 'SubnetNamePublic${Az}':
      Description:
        Fn::Sub: The Name of the public subnet in ${AWS::Region}${Az}
      Value:
        Fn::Sub: public-${AWS::Region}${Az}
    'SubnetNamePrivate${Az}':
      Description:
        Fn::Sub: The Name of the private subnet in ${AWS::Region}${Az}
      Value:
        Fn::Sub: private-${AWS::Region}${Az}
  Fn::ForEach::RouteTableIDs:
  - Az
  - ['a', 'b', 'c']
  - 'RouteTableIDPrivate${Az}':
      Description:
        Fn::Sub: The ID of the private subnet's route table in ${AWS::Region}${Az}
      Value:
        Ref:
          Fn::Sub: 'PrivateRouteTable${Az}'
