AWSTemplateFormatVersion: '2010-09-09'
Description: Creates a Jenkins server using JDK 17 on an Amazon Linux 2 EC2 instance with a custom security group allowing ports 80, 8080, and 22 from anywhere.

Parameters:
  InstanceType:
    Type: String
    Default: t2.micro
    Description: The type of EC2 instance to launch.

Resources:
  JenkinsSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Jenkins security group
      SecurityGroupIngress:
      - CidrIp: 0.0.0.0/0
        FromPort: 80
        ToPort: 80
        IpProtocol: tcp
      - CidrIp: 0.0.0.0/0
        FromPort: 8080
        ToPort: 8080
        IpProtocol: tcp
      - CidrIp: 0.0.0.0/0
        FromPort: 22
        ToPort: 22
        IpProtocol: tcp

  JenkinsInstance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-0e8a34246278c21e4 # Amazon Linux 2 AMI
      InstanceType: !Ref InstanceType
      SecurityGroups:
      - !Ref JenkinsSecurityGroup
      KeyName: new
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash

          yum update -y
          hostnamectl set-hostname jenkins-server
          yum install git -y
          yum install java-11-amazon-corretto -y
          wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
          rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    
          yum install jenkins -y
          systemctl start jenkins
          systemctl enable jenkins
          amazon-linux-extras install docker -y
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
          usermod -a -G docker jenkins
          cp /lib/systemd/system/docker.service /lib/systemd/docker.service.bak
          sed -i 's/^ExecStart=.*/ExecStart=\/usr\/bin\/dockerd -H tcp:\/\/127.0.0.1:2375 -H unix:\/\/\/var\/run\/docker.sock/g' /lib/systemd/system/docker.service
          systemctl restart docker
          systemctl restart jenkins

          rm -rf /bin/aws

          curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
          unzip awscliv2.zip
          ./aws/install

          


