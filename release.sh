#!/bin/bash


RPOJECT_NAME=
PROJECT_IMAGE=

gcloud config set project $PROJECT_NAME
gcloud config set compute/zone us-central1-c

ran=$RANDOM

echo "What do you want to do ?"
echo "1. Release new build "
echo "2. Rollback to previous build"
read -p "Input [1/2]:" res

if [ "$res" = "1" ]
then

gcloud compute instances stop base --zone=us-central1-c
gcloud compute images create image-$(date +%Y%m%d)-$ran --source-disk=base --source-disk-zone=us-central1-c

gcloud compute instance-templates create template-$(date +%Y%m%d)-$ran --machine-type=g1-small --image=image-$(date +%Y%m%d)-$ran --image-project=$PROJECT_NAME --boot-disk-size=30 --network=custom-vpc --subnet=custom-subnet --region=us-central1  --tags=http-server,https-server

gcloud beta compute instance-groups managed rolling-action start-update custom-group --version template=template-$(date +%Y%m%d)-$ran --zone us-central1-c
gcloud compute instances delete base

elif [ "$res" = "2" ]
then
gcloud compute instance-templates list | grep "template*"
read -p "Input instance template name : " instance_template_name

while true; do
    read -p "You choose $instance_template_name , is that correct ? [Y/n]" yn
    case $yn in
        [Yy]* ) gcloud beta compute instance-groups managed rolling-action start-update custom-group --version template=template-$(date +%Y%m%d)-$UUID --region us-central1; break;;
	[Nn]* ) echo "Okay! Cancelled."; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
else
echo "Input must be either 1 or 2"
fi
