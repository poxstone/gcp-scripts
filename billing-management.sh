#!/usr/bin/bash

# gsutil cp gs://billing-management-xertica/billing-management.sh ./ && source ./billing-management.sh;
param_1=`echo "${1}" | awk '{gsub("[ ]","",$0);print tolower($0)}'`;
param_2=`echo "${2}" | awk '{gsub("[ ]","",$0);print tolower($0)}'`;

function getVars {
  GCP_USER=`gcloud info --format="value(config.account)"`;
  GCP_DOMAIN="${1}";
  [[ $GCP_DOMAIN != '' ]] && GCP_USER_DOMAIN="${GCP_DOMAIN}" || GCP_USER_DOMAIN=`echo $GCP_USER | awk -F '@' '{print($2)}'`;
  GCP_ERROR_USER_1="VALIDE SI SU CUENTA PERTENECE A UNA ORGANIZACIÓN Y TIENE PERMISOS DE SUPERADMINISTRADOR EN LA ORGANIZACIÓN";
  GCP_PREFIX="billingxerti-";
  GCP_SA_NAME="${GCP_PREFIX}sa"
  GCP_PERMISSIONS=("roles/logging.viewAccessor" "roles/monitoring.viewer" "roles/viewer");
  GCP_FILE_ERRROR_LOGS="${BASH_SOURCE}.log";
  
  # get variables
  GCP_ORG=`gcloud organizations list --format="value(displayName)" --filter="displayName=${GCP_USER_DOMAIN}"`;
  if [[ "${GCP_ORG}" != "" ]];then
    GCP_NUM=`gcloud organizations list --format="value(name)" --filter="displayName=${GCP_USER_DOMAIN}"`;
    if [[ "${GCP_NUM}" != "" ]];then
      GCP_ORG_SHORT=`echo "${GCP_ORG}" | awk '{gsub("[^a-z]+","",$0);print tolower($0)}'`;
      GCP_PJ=`echo "${GCP_PREFIX}${GCP_ORG_SHORT}" | cut -c1-30`;
      
      GCP_SA_FILE="key-${GCP_SA_NAME}-${GCP_ORG}.json";
      [[ $GCP_AS_EMAIL == '' ]] && GCP_AS_EMAIL="";
      echo "variables configuradas";

    else
      echo "NO SE ENCONTRÓ NÚMERO DE ORGANIZACIÓN ${GCP_ERROR_USER_1}";
    fi;
    
  else
    echo "NO SE ENCONTRÓ LA ORGANIZACIÓN ${GCP_USER_DOMAIN} ${GCP_ERROR_USER_1}";
  fi;
  
}

# crear proyecto
function create_GCP_project {
  echo "INFO $(date) - ${GCP_ORG} creación de proyecto ${GCP_PJ}" >> "${GCP_FILE_ERRROR_LOGS}";
  PJ_EXIST=`gcloud projects list --format="value(projectId)" --filter="projectId=${GCP_PJ}"`;
  if [[ "${PJ_EXIST}" != "" ]];then
    echo "El proyecto ${GCP_PJ} ya existe, vamos a utilizarlo";
  else
    echo "El proyecto ${GCP_PJ} va ha ser creado...";
    gcloud organizations add-iam-policy-binding "${GCP_NUM}" --member="user:${GCP_USER}" --role="roles/resourcemanager.projectCreator" && sleep 10 && \
    gcloud projects create "${GCP_PJ}" --organization="${GCP_NUM}" --labels="monitoreo=xertica" --enable-cloud-apis && \
    sleep 60 && \
    echo "El proyecto ${GCP_PJ} fue creado correctamente" || \
    echo "ERROR $(date) - ${GCP_ORG} AL CREAR EL PROYECTO ${GCP_PJ} por ${GCP_ERROR_USER_1}" >> "${GCP_FILE_ERRROR_LOGS}";
  fi;
  gcloud config set project "${GCP_PJ}";
}

function enable_project_services {
  echo "INFO $(date) - ${GCP_ORG} habilitar servicios de proyecto ${GCP_PJ}" >> "${GCP_FILE_ERRROR_LOGS}";
  gcloud services enable "cloudapis.googleapis.com" "clouddebugger.googleapis.com" "logging.googleapis.com" "monitoring.googleapis.com" "servicemanagement.googleapis.com" "serviceusage.googleapis.com" "storage-api.googleapis.com" "storage-component.googleapis.com" "clouderrorreporting.googleapis.com" "cloudresourcemanager.googleapis.com" --project="${GCP_PJ}" || \
  echo "ERROR $(date) - ${GCP_ORG} ERROR HABILITANDO servicios de proyecto ${GCP_PJ}" >> "${GCP_FILE_ERRROR_LOGS}";
}

function delete_GCP_project {
  echo "INFO $(date) - ${GCP_ORG} eliminación de proyecto ${GCP_PJ}" >> "${GCP_FILE_ERRROR_LOGS}";
  PJ_EXIST=`gcloud projects list --format="value(projectId)" --filter="projectId=${GCP_PJ}"`;
  if [[ "${PJ_EXIST}" != "" ]];then
    echo "El proyecto ${GCP_PJ} va ha ser ELIMINADO...";
    gcloud projects delete "${GCP_PJ}" -q && \
    echo "El proyecto ${GCP_PJ} fue creado eliminado" || echo "El proyecto ${GCP_PJ} NO PUDO SER ELIMINADO, por favor revise los permisos del usuario";
  else
    echo "El proyecto ${GCP_PJ} no existe o no hay permmisos para verlo";
  fi;
}

function get_SA_name {
  GCP_AS_EMAIL=`gcloud iam service-accounts list --format="value(email)" --filter="displayName=${GCP_SA_NAME}" --project="${GCP_PJ}"`;
  echo "${GCP_AS_EMAIL}";
}

# habilitar APIS y servicios

# create cuenta de servicio
function create_service_account {
  echo "INFO $(date) - ${GCP_ORG} crear cuenta de servicio ${GCP_SA_NAME} en proyecto ${GCP_PJ}" >> "${GCP_FILE_ERRROR_LOGS}";
  AS_EXIST=`gcloud iam service-accounts list --format="value(email)" --filter="displayName=${GCP_SA_NAME}" --project="${GCP_PJ}"`;
  if [[ "${AS_EXIST}" != "" ]];then
    echo "La cuenta de servicio ${GCP_SA_NAME} ya existe, vamos a utilizarla";
  else
    echo "Se creara la cuenta de servicio ${GCP_SA_NAME}...";
    gcloud iam service-accounts create "${GCP_SA_NAME}" --description="Cuenta de servicio para monitoreo xertica" --display-name="${GCP_SA_NAME}" --project="${GCP_PJ}";
  fi;
  sleep 10;
  get_SA_name;
  sleep 10;
  # create key
  AS_KEY_EXISTS=`gcloud iam service-accounts keys list --iam-account="${GCP_AS_EMAIL}" --format="value(keyType)" --filter="keyType=USER_MANAGED" --project="${GCP_PJ}"`;
  if [[ "${AS_KEY_EXISTS}" != "" ]];then
    echo "Existen llaves de la cuenta de servicio ${GCP_SA_NAME} se procederá aborrar y crear una nueva";
    rm -rf "${GCP_SA_FILE}";
    KEY_LIST=`gcloud iam service-accounts keys list --iam-account="${GCP_AS_EMAIL}" --format="value(name)" --filter="keyType=USER_MANAGED" --project="${GCP_PJ}"`;
    for i in ${KEY_LIST};do
      gcloud iam service-accounts keys delete "${i}" --iam-account="${GCP_AS_EMAIL}" --project="${GCP_PJ}" -q;
    done;
  fi;
  gcloud iam service-accounts keys create "${GCP_SA_FILE}" --iam-account="${GCP_AS_EMAIL}" --project="${GCP_PJ}";
}

function add_permissions {
  get_SA_name;
  echo "INFO $(date) - ${GCP_ORG} asignar permisos en la organización para la cuenta de servicio ${GCP_SA_NAME}" >> "${GCP_FILE_ERRROR_LOGS}";
  # add owner in self project
  gcloud projects add-iam-policy-binding "${GCP_PJ}" --member="serviceAccount:${GCP_AS_EMAIL}" --role="roles/owner";
  # add permissions in organizaion
  for permission in ${GCP_PERMISSIONS[@]}; do
    gcloud organizations add-iam-policy-binding "${GCP_NUM}" --member="serviceAccount:${GCP_AS_EMAIL}" --role="${permission}" && \
    echo "PERMISOS ${permission} asignado" || \
    echo "ERROR $(date) - ${GCP_ORG} ASIGNANDO PERMISO ${permission} a la organización" >> "${GCP_FILE_ERRROR_LOGS}";
  done;
}

function remove_permissions {
  get_SA_name;
  echo "INFO $(date) - ${GCP_ORG} remover permisos en la organización para la cuenta de servicio ${GCP_SA_NAME}" >> "${GCP_FILE_ERRROR_LOGS}";
  for permission in ${GCP_PERMISSIONS[@]}; do
    gcloud organizations remove-iam-policy-binding "${GCP_NUM}" --member="serviceAccount:${GCP_AS_EMAIL}" --role="${permission}" || \
    echo "ERROR $(date) - ${GCP_ORG} remover permisos ${GCP_SA_NAME} ${permission}" >> "${GCP_FILE_ERRROR_LOGS}";
  done;
  rm -rf "${GCP_SA_FILE}";
}

# execute
if [[ "${param_1}" == "" ]];then
  echo "get org by user email";
  GCP_DOMAIN="";
  getVars "${GCP_DOMAIN}";
  create_GCP_project;
  enable_project_services;
  create_service_account;
  add_permissions;
  cat $GCP_SA_FILE;
elif [[ "${param_1}" == *".csv" || "${param_1}"  == *".txt" ]];then
  echo "get by file list ${param_1}";
  for domain in $(cat ${param_1});do
    bash ${BASH_SOURCE} ${domain};
  done;
elif [[ "${param_1}" == "delete" ]];then
  if [[ "${param_2}" == *".csv" || "${param_2}"  == *".txt" ]];then
    echo "delete permissions for ${param_2}";
    for domain in $(cat ${param_2});do
      bash ${BASH_SOURCE} delete ${domain};
    done;
    # zip keys
    zip "keys-${BASH_SOURCE}.zip" "key-*.json";

  else
    echo "delete permissions and project from user email";
    [[ ${param_2} == "" ]] && GCP_DOMAIN="" || GCP_DOMAIN="${param_2}";
    getVars "${GCP_DOMAIN}";
    delete_GCP_project;
    remove_permissions;
  fi;
else
  echo "get organization ${param_1}";
  GCP_DOMAIN="${param_1}";
  getVars "${GCP_DOMAIN}";
  create_GCP_project;
  enable_project_services;
  create_service_account;
  add_permissions;
  cat $GCP_SA_FILE;
fi;
