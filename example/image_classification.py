import os
import ast
import time
import argparse
import logging

import autogluon as ag
from autogluon import ImageClassification as task

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

def train(args):
    print("args {}".format(args))
    is_distributed = len(args.hosts) > 1
    dist_ip_addrs = []
    if is_distributed:
        host_rank = args.hosts.index(args.current_host)
        ag.sagemaker_setup()
        if host_rank > 0:
            print('Host rank {} exit.'.format(host_rank))
            return

    dist_ip_addrs = args.hosts
    dist_ip_addrs.pop(host_rank)
    dataset = task.Dataset(os.path.join(args.data_dir, 'train'))
    ngpus_per_trial = 1 if args.num_gpus > 0 else 0

    classifier = task.fit(dataset,
                          epochs=args.epochs,
                          ngpus_per_trial=ngpus_per_trial,
                          verbose=True,
                          dist_ip_addrs=dist_ip_addrs,
                          checkpoint=os.path.join(args.model_dir, 'exp1.ag'))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # The parameters below retrieve their default values from SageMaker environment variables, which are
    # instantiated by the SageMaker containers framework.
    # https://github.com/aws/sagemaker-containers#how-a-script-is-executed-inside-the-container
    parser.add_argument('--epochs', type=int, default=2, metavar='E',
                        help='number of total epochs to run (default: 2)')
    parser.add_argument('--hosts', type=str, default=ast.literal_eval(os.environ['SM_HOSTS']))
    parser.add_argument('--current-host', type=str, default=os.environ['SM_CURRENT_HOST'])
    parser.add_argument('--model-dir', type=str, default=os.environ['SM_MODEL_DIR'])
    parser.add_argument('--data-dir', type=str, default=os.environ['SM_CHANNEL_TRAINING'])
    parser.add_argument('--num-gpus', type=int, default=os.environ['SM_NUM_GPUS'])

    args = parser.parse_args()
    train(args)
    ag.done()
