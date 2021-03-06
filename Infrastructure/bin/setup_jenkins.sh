#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student
oc project ${GUID}-jenkins
oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi
#oc set resources dc jenkins --limits=memory=2Gi,cpu=2 --requests=memory=2Gi,cpu=2

# custom maven image
/usr/bin/sudo -i
cat > /etc/containers/registries.conf << EOF
# This is a system-wide configuration file used to
# keep track of registries for various container backends.
# It adheres to TOML format and does not support recursive
# lists of registries.

# The default location for this configuration file is /etc/containers/registries.conf.

# The only valid categories are: 'registries.search', 'registries.insecure',
# and 'registries.block'.

[registries.search]
registries = ['registry.access.redhat.com']

# If you need to access insecure registries, add the registry's fully-qualified name.
# An insecure registry is one that does not have a valid SSL certificate or only does HTTP.
[registries.insecure]
registries = ['docker-registry-default.apps.${CLUSTER}']


# If you need to block pull access from a registry, uncomment the section below
# and add the registries fully-qualified name.
#
# Docker only
[registries.block]
registries = []
EOF

/usr/bin/systemctl enable docker
/usr/bin/systemctl restart docker

mkdir $HOME/jenkins-slave-appdev
cd  $HOME/jenkins-slave-appdev
cat > Dockerfile << EOF
FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9
USER root
RUN yum -y install skopeo apb && \
    yum clean all
USER 1001
EOF
/usr/bin/docker build . -t docker-registry-default.apps.${CLUSTER}/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9
/usr/bin/docker login -u ${GUID} -p $(oc whoami -t) docker-registry-default.apps.${CLUSTER}
/usr/bin/docker push docker-registry-default.apps.${CLUSTER}/${GUID}-jenkins/jenkins-slave-maven-appdev:v3.9

# sudo

# create jenkins pipelines using custom image
cat ../templates/mlbparks-jenkins.yaml      | oc create -f - -n ${GUID}-jenkins
cat ../templates/nationalparks-jenkins.yaml | oc create -f - -n ${GUID}-jenkins
cat ../templates/parksmap-jenkins.yaml      | oc create -f - -n ${GUID}-jenkins

