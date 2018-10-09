# AWS Toil #

This guide should take you through the steps required for running the workflow on an AWS cluster (instead of local machine mode)

## Local Initialization ##

This should be run on your local box.  It requires you to have an AWS key existing.  Be sure to match the toil version with the one used by the workflow (see version.py)

```
sudo pip install awscli --upgrade
sudo pip install toil aws --upgrade

# launch cluster
ssh-add ~/.ssh/$KEY_NAME.pem 

# this command timed out once, then I ran it again with a different name and it worked almost immediately
toil launch-cluster $CLUSTER_NAME --leaderNodeType t2.medium --zone us-west-2a --keyPairName $KEY_NAME

# log onto cluster
toil ssh-cluster --zone us-west-2a $CLUSTER_NAME
```

## Remote Initialization ## 

This should be run after logging into the toil master node.  This portion should only need to be run once (per cluster initialization).  The virtualenv initialized here is copied to the worker nodes, so it is important that it is initialized appropriately.  

```
# prep
apt-get update
apt-get install -y git s3cmd vim
s3cmd --configure

# get marginPhase and setup environment
cd /opt
git clone https://github.com/UCSC-nanopore-cgl/toil-marginPhase.git
virtualenv --system-site-packages venv
. venv/bin/activate
pip install --upgrade mesos.cli
pip install --upgrade s3am
pip install --upgrade .
deactivate # I don't know if you actually need to deactivate the venv
```

This gets the appropriate configuration (assuming it lives on s3 somewhere).  This can be used to run multiple workflows once the box itself is initialized.  Running 'script' and 'screen' is required to keep it running after ssh terminates.

The AWS configuration described can be modified for different spot market pricing and cluster size.

```
# get workflow configuration
s3cmd ls s3://path/to/configuration/
s3cmd get s3://path/to/configuration/$CONFIG.yaml &amp;&amp; mv $CONFIG.yaml config-toil-marginphase.yaml
s3cmd get s3://path/to/configuration/$MANIFEST.tsv &amp;&amp; mv $MANIFEST.tsv manifest-toil-marginphase.tsv

# run the workflow
script
screen
cd /opt/toil-marginPhase
. venv/bin/activate

toil-marginphase run --defaultCores 1 --maxMemory 60G --maxCores 8 --defaultPreemptable --batchSystem mesos --provisioner aws --nodeTypes m4.4xlarge:0.5 --nodeStorage 500 --maxNodes 2 --minNodes 1 aws:us-west-2:$JOBSTORE 2>&1 | tee -a toil-marginphase.$JOBSTORE.log

# watch it run
Ctrl-A d #detach from screen
exit #leave the script
export LOG=/opt/toil-marginPhase/toil-marginphase.$JOBSTORE.log &amp;&amp; watch "cat $LOG | grep leader | sed 's/^.*leader://' | grep 'Job ended successfully' | grep --invert-match INFO | wc -l &amp;&amp; echo '----' &amp;&amp; cat $LOG | grep leader | sed 's/^.*leader://' | grep 'Issued job' | grep --invert-match INFO | wc -l &amp;&amp; echo '\n' &amp;&amp; wc -l $LOG &amp;&amp; echo '\n' &amp;&amp; cat $LOG | grep leader | sed 's/^.*leader://' | grep --invert-match leader | tail -42"
```