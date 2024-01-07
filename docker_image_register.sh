#!/bin/bash

# Set SystemName
SYSTEM_NAME=template

# Set EnvType
ENV_TYPE=dev

# Set RegionName
REGION_NAME=tokyo

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get AWS Region
AWS_REGION=$(aws configure get region --profile ${SYSTEM_NAME}-${ENV_TYPE}-${REGION_NAME})

# Login ECR
aws ecr get-login-password \
    --profile ${SYSTEM_NAME}-${ENV_TYPE}-${REGION_NAME} |
    docker login \
        --username AWS \
        --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build Docker Image
docker compose build --no-cache

# Set timestamp
timestamp=$(date +"%Y%m%d-%H_%M_%S")

# Set Docker Tag
docker tag tmp-bastion ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bastion:${timestamp}
docker tag tmp-bastion ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bastion:latest

# Push Docker Image
docker push -a ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bastion

# Remove tmp Docker Image
docker rmi tmp-bastion

exit 0
