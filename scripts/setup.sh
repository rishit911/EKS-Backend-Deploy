#!/bin/bash

# Set variables
CLUSTER_NAME="nextwork-eks-cluster"
REGION="YOUR-REGION"
NODE_TYPE="t2.micro"
NODES=3
MIN_NODES=1
MAX_NODES=3
ECR_REPO_NAME="nextwork-flask-backend"

# Create EKS cluster
echo "Creating EKS cluster..."
eksctl create cluster \
  --name $CLUSTER_NAME \
  --nodegroup-name nextwork-nodegroup \
  --node-type $NODE_TYPE \
  --nodes $NODES \
  --nodes-min $MIN_NODES \
  --nodes-max $MAX_NODES \
  --version 1.31 \
  --region $REGION

# Create ECR repository
echo "Creating ECR repository..."
aws ecr create-repository \
  --repository-name $ECR_REPO_NAME \
  --image-scanning-configuration scanOnPush=true

# Get ECR repository URI
ECR_REPO_URI=$(aws ecr describe-repositories --repository-names $ECR_REPO_NAME --query 'repositories[0].repositoryUri' --output text)

# Update deployment.yaml with ECR repository URI
sed -i "s|YOUR-ECR-IMAGE-URI-HERE|$ECR_REPO_URI:latest|g" ../kubernetes/deployment.yaml

# Build and push Docker image
echo "Building and pushing Docker image..."
cd ../backend
docker build -t $ECR_REPO_NAME .
docker tag $ECR_REPO_NAME:latest $ECR_REPO_URI:latest
docker push $ECR_REPO_URI:latest

# Deploy application
echo "Deploying application..."
cd ../kubernetes
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

echo "Setup complete! Your application is being deployed..." 