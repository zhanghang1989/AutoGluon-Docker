#!/usr/bin/env bash

# This script shows how to build the Docker image and push it to ECR to be ready for use
# by SageMaker.

# The argument to this script is the image name. This will be used as the image on the local
# machine and combined with the account and region to form the repository name for ECR.
image=$1

if [ "$image" == "" ]
then
    echo "Usage: $0 <image-name>"
    exit 1
fi

# Get the account number associated with the current IAM credentials
account=$(aws sts get-caller-identity --query Account --output text)

if [ $? -ne 0 ]
then
    exit 255
fi

# Get the region defined in the current configuration (default to us-west-2 if none defined)
region=$(aws configure get region)
region=${region:-us-west-2}


#fullname="${account}.dkr.ecr.${region}.amazonaws.com/${image}:latest"
ECR_URL="${account}.dkr.ecr.${region}.amazonaws.com"


DLAMI_REGISTRY_ID=763104351884

# Get the login command from ECR and execute it directly
$(aws ecr get-login --region ${region} --no-include-email)

# Get the login command from ECR in order to pull down the SageMaker MXNet image
$(aws ecr get-login --registry-ids ${DLAMI_REGISTRY_ID} --region ${region} --no-include-email)

# Build the docker image locally with the image name and then push it to ECR
# with the full name.

for context in "cpu-py36" "gpu-py36-cu100"
do
    image_name=${image}-${context}
    # If the repository doesn't exist in ECR, create it.
    aws ecr describe-repositories --repository-names "${image_name}" > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        aws ecr create-repository --repository-name "${image_name}" > /dev/null
    fi
    # build the image
    docker build -t ${image_name} . \
                 --build-arg REGION=${region} \
                 --build-arg DLAMI_REGISTRY_ID=${DLAMI_REGISTRY_ID} \
                 --build-arg CONTEXT=${context}
    # tag and push
    docker tag ${image_name} ${ECR_URL}/${image_name}
    docker push ${ECR_URL}/${image_name}
done
