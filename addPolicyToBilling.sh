#/bin/bash

echo "Este script AÑADIRÁ PERMISO DE BILLING a un usuario en proyectos GCP
Presione cualquier tecla para continuar...";

GCP_PERMISSIONS=("roles/browser", "roles/billing.projectManager");
GCP_PERMISSIONS_ORG=("roles/resourcemanager.organizationViewer", "roles/browser", "roles/billing.projectManager");
USER_BILLING="${1}";
if [[ "${2}" != "" && "${2}" != *"."* ]];then
  PROJECTS_ID=(${@});
elif [[ "${2}" == "" || "${2}" == *"."* ]];then
  GCP_USER=`gcloud info --format="value(config.account)"`;
  GCP_DOMAIN="${2}";
  [[ "${GCP_USER}" != "" ]] && GCP_USER_DOMAIN=`echo ${GCP_USER} | awk -F '@' '{print($2)}'` || GCP_USER_DOMAIN="${GCP_DOMAIN}";
  GCP_NUM=`gcloud organizations list --format="value(name)" --filter="displayName=${GCP_USER_DOMAIN}"`;
fi;

if [[ "${PROJECTS_ID}" != "" ]];then
  echo "set permissions on projects ${PROJECTS_ID[@]:1}";
  for project in ${PROJECTS_ID[@]:1};do
    for permission in ${GCP_PERMISSIONS[@]};do
      gcloud projects add-iam-policy-binding "${project}" --member="user:${USER_BILLING}" --role="${permission}";
    done;
  done;
elif [ "${GCP_NUM}" != "" ];then
  echo "set permissions on org ${GCP_NUM}";
  for permission in ${GCP_PERMISSIONS_ORG[@]};do
    gcloud organizations add-iam-policy-binding "${GCP_NUM}" --member="user:${USER_BILLING}" --role="${permission}";
  done;
fi;
