# AutoGluon Setup for SageMaker Estimator

This is a step-by-step tutorial of running AutoGluon using SageMaker Estimator. We assume you are already familiar with AWS SageMaker. Otherwise, please refer to the tutorial of AutoGluon Distributed Training on dedicated machines.

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

### Upload to s3
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

## Sumbit A Training Job

Get the ECR image name:

```python
import boto3

client = boto3.client('sts')
account = client.get_caller_identity()['Account']

my_session = boto3.session.Session()
region = my_session.region_name

algorithm_name = 'autogluon-cifar10-example'

ecr_image = '{}.dkr.ecr.{}.amazonaws.com/{}:latest'.format(account, region, algorithm_name)

print(ecr_image)
```

Get the SageMaker role

```
from sagemaker import get_execution_role

role = get_execution_role()
```

Start the SageMaker Estimator fit:

```python
from sagemaker.estimator import Estimator

hyperparameters = {'epochs': 1}

instance_type = 'ml.p3.2xlarge'

estimator = Estimator(role=role,
                      train_instance_count=1,
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
