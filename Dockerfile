# Copyright 2017-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

# For more information on creating a Dockerfile
# https://docs.docker.com/compose/gettingstarted/#step-2-create-a-dockerfile
# https://github.com/awslabs/amazon-sagemaker-examples/
ARG REGION=us-west-2
ARG CONTEXT=cpu-py36
ARG DLAMI_REGISTRY_ID=763104351884

# SageMaker MXNet image
# Registry ID from: https://docs.aws.amazon.com/dlami/latest/devguide/deep-learning-containers-images.html
FROM ${DLAMI_REGISTRY_ID}.dkr.ecr.${REGION}.amazonaws.com/mxnet-training:1.4.1-${CONTEXT}-ubuntu16.04

# Install OpenSSH for MPI to communicate between containers
RUN apt-get install -y --no-install-recommends openssh-client openssh-server
RUN mkdir -p /var/run/sshd && \
  sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN rm -rf /root/.ssh/ && \
  mkdir -p /root/.ssh/ && \
  ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa && \
  cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
  printf "Host *\n  StrictHostKeyChecking no\n" >> /root/.ssh/config

# Install dependencies, ordering from general to specific.
# Copy this specific `requirements.txt` file first, and defer copying the
# entire directory to last.
COPY requirements.txt requirements.txt
# This way changes to its contents won't invalidate the cache and we wouldn't
# have to re-install dependencies.
# Need to pre-install `cython` for ConfigSpace.
RUN python -m pip install --upgrade pip
RUN python -m pip install Cython==0.29.13
RUN	python -m pip install --no-cache-dir -r requirements.txt
RUN	python -m spacy download en

# We deliberately don't install the dependencies here to improve 
# build times by maximally utilizing the build cache. All dependencies
# should be centralized in `requirements.txt` above.
COPY autogluon autogluon/
# RUN python -m pip install --no-deps -e autogluon/
RUN python -m pip install -e autogluon/

ENV PATH="/opt/ml/code:${PATH}"

# /opt/ml and all subdirectories are utilized by SageMaker, we use the /code subdirectory to store our user code.
COPY /example /opt/ml/code

# this environment variable is used by the SageMaker PyTorch container to determine our user code directory.
ENV SAGEMAKER_SUBMIT_DIRECTORY /opt/ml/code

# this environment variable is used by the SageMaker PyTorch container to determine our program entry point
# for training and serving.
# For more information: https://github.com/aws/sagemaker-pytorch-container
ENV SAGEMAKER_PROGRAM image_classification.py
