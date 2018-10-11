#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

LABEL=parksmap
# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student
oc policy add-role-to-group system:image-puller system:serviceaccounts:${GUID}-parks-prod -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod

# Create Blue Application
oc new-app ${GUID}-parks-dev/${LABEL}:0.0 --name=${LABEL}-blue --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/${LABEL}-blue --remove-all -n ${GUID}-parks-prod
oc expose dc ${LABEL}-blue --port 8080 -n ${GUID}-parks-prod
oc create configmap ${LABEL}-blue-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-parks-prod
oc set volume dc/${LABEL}-blue --add --name=jboss-config  --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=${LABEL}-blue-config -n ${GUID}-parks-prod
oc set volume dc/${LABEL}-blue --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=${LABEL}-blue-config -n ${GUID}-parks-prod

# Create Green Application
oc new-app ${GUID}-parks-dev/${LABEL}:0.0 --name=${LABEL}-green --allow-missing-imagestream-tags=true -n ${GUID}-parks-prod
oc set triggers dc/${LABEL}-green --remove-all -n ${GUID}-parks-prod
oc expose dc ${LABEL}-green --port 8080 -n ${GUID}-parks-prod
oc create configmap ${LABEL}-green-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n ${GUID}-parks-prod
oc set volume dc/${LABEL}-green --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=${LABEL}-green-config -n ${GUID}-parks-prod
oc set volume dc/${LABEL}-green --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=${LABEL}-green-config -n ${GUID}-parks-prod

# Expose Blue service as route to make blue application active
oc expose svc/${LABEL}-blue --name ${LABEL} -n ${GUID}-parks-prod
