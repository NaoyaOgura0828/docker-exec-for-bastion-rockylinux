#!/bin/bash

# Set AWS Region
AWS_REGION=ap-northeast-1

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Login ECR
aws ecr get-login-password \
    --region ap-northeast-1 |
    docker login \
        --username AWS \
        --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com

# Build Docker Image
docker compose build --no-cache

# Set timestamp
timestamp=$(date +"%Y%m%d-%H_%M_%S")

# Set Docker Tag
docker tag tmp-bastion ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/bastion:${timestamp}
docker tag tmp-bastion ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/bastion:latest

# Push Docker Image
docker push -a ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/bastion

# Remove tmp Docker Image
docker rmi tmp-bastion

exit 0
