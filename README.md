# AutoGluon Setup for SageMaker Estimator

This is a step-by-step tutorial of running AutoGluon using SageMaker Estimator. We assume you are already familiar with AWS SageMaker. Otherwise, please refer to the tutorial of AutoGluon Distributed Training on dedicated machines.

```bash
git clone https://github.com/zhanghang1989/AutoGluon-Docker --recursive
```

## Built Docker and Push It onto ECR

```bash
bash build_and_push.sh autogluon-cifar10-example
```

## Upload Dataset

### Download the dataset

```
import autogluon as ag
filename = ag.download('https://autogluon.s3.amazonaws.com/datasets/shopee-iet.zip')
ag.unzip(filename)
```

### Upload the dataset to s3
Get a SageMaker section:

```
import sagemaker as sage
sess = sage.Session()
```

Upload the data:

```
prefix = 'DEMO-autogluon-cifar10'
data_location = sess.upload_data('./data', key_prefix=prefix)
```

## Sumbit A training Job

Get the ECR image name:

```python
import boto3

client = boto3.client('sts')
account = client.get_caller_identity()['Account']

my_session = boto3.session.Session()
region = my_session.region_name

# You can also chooise the CPU docker, which we built in the first stage.
algorithm_name = 'autogluon-cifar10-example-gpu-py36-cu100'

ecr_image = '{}.dkr.ecr.{}.amazonaws.com/{}:latest'.format(account, region, algorithm_name)
print(ecr_image)
```

Get the SageMaker role

```
from sagemaker import get_execution_role
role = get_execution_role()
# You may need to mannually set the role SageMaker role name.
```

Start the SageMaker Estimator fit:

```python
from sagemaker.estimator import Estimator

hyperparameters = {'epochs': 1}

instance_type = 'ml.p3.2xlarge'

estimator = Estimator(role=role,
                      train_instance_count=2,
                      train_instance_type=instance_type,
                      image_name=ecr_image,
                      hyperparameters=hyperparameters)

estimator.fit(data_location)
```

## Get The Model from S3

You can checkout the checkerpoint files on S3:

```bash
aws s3 ls s3://sagemaker-{region}-{account}/autogluon-cifar10/
```

# FAQ

## Setup on AWS

### Create IAM User
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html

### Setup A SageMaker Role

### Configure Your AWS CLI

## Other Questions:

### The current AWS identity is not a role for sagemaker:

https://stackoverflow.com/questions/47710558/the-current-aws-identity-is-not-a-role-for-sagemaker
