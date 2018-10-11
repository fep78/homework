#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.
LABEL=parksmap

# To be Implemented by Student
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev
oc new-build --binary=true --name=${LABEL} jboss-eap70-openshift:1.6 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/${LABEL}:0.0-0 --name=${LABEL} --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc set triggers dc/${LABEL} --remove-all -n ${GUID}-parks-dev
oc expose dc ${LABEL} --port 8080 -n ${GUID}-parks-dev
oc expose svc ${LABEL} -n ${GUID}-parks-dev
oc create configmap ${LABEL}-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-parks-dev
oc set volume dc/${LABEL} --add --name=jboss-config  --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=${LABEL}-config -n ${GUID}-parks-dev
oc set volume dc/${LABEL} --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=${LABEL}-config -n ${GUID}-parks-dev
