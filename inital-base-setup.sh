#!/bin/sh


PROJECT_NAME=

if [  -z "$1" ]
then
	echo "You need to include the repository branch  ex. ./deploy-image-to-staging-base-scratchpay..sh <branch>"
else
	gcloud config set project $PROJECT_NAME
	gcloud config set compute/zone us-central1-c
	gcloud beta compute --project=scratch-staging-221817 instances create base --zone=us-central1-c --machine-type=g1-small --subnet=custom-subnet --network-tier=PREMIUM  --address=35.193.69.230 --maintenance-policy=MIGRATE  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=http-server,https-server --image=ubuntu-1804-bionic-v20200701 \
--image-project=ubuntu-os-cloud --boot-disk-size=30GB  --scopes=https://www.googleapis.com/auth/cloud-platform \
--boot-disk-type=pd-standard --boot-disk-device-name=base \
--metadata startup-script-url=<URL>/server-script.sh,laravel-version=$1


echo "Waiting for instance to build, please check for your email"
sleep 8m

fi

