#/bin/bash

echo "Este script leerá TODOS LOS PROYECTOS A LOS QUE TENGA ACCESO PERO NO MODIFICARÁ NADA!
Presione cualquier tecla para continuar...";
read -n 1 -s -r -p ""

[[ -z "${1}" ]] && ACCOUNT_EMAIL=$(gcloud config get account) || ACCOUNT_EMAIL="${1}";
[[ -z "${2}" ]] && LIMIT=9999999 || LIMIT="${2}";
[[ -z "${3}" ]] && BILLING="y" || BILLING="${3}";
FILE_OUT=`echo projects_roles_$(echo $ACCOUNT_EMAIL | awk -F'@' '{print($1"--"$2)}').csv`;
orgsfolds=();

function getOrgFold() {
  local parentId="${1}";
  local parentType="${2}";
  local parentData="";

  for (( i=0; i<=${#orgsfolds[@]}; i++ ));do
    local parentOF="${orgsfolds[$i]}";
    if [[ "${parentOF}" == *"${parentId}"* ]];then
      parentData="${parentOF}";
    fi;
  done;

  if [[ "${parentData}" == "" ]];then
    if [[ "${parentType}" == "folder" ]];then
        parentData=`gcloud resource-manager folders describe "${parentId}" --format="value(displayName,parent)" || echo "NONE"`;
    elif [[ "${parentType}" == "organization" ]];then
        parentData=`gcloud organizations describe "${parentId}" --format="value(displayName,owner.directoryCustomerId)" || echo "NONE"`;
    else
        parentData="NO_PARENT_DATA";
    fi;
    local len="${#orgsfolds[@]}";
    local parent_getter="${parentId}:(${parentData})";
    orgsfolds[len]="${parent_getter}";
    echo "${parent_getter}";
  else
    echo "${parentData}";
  fi;
}

function getProjects {
  gcloud projects list --format "csv(projectId,name,projectNumber,parent.id,parent.type,createTime,lifecycleState)" --limit ${LIMIT} | while IFS= read -r lines; do
    local projectId=$(echo ${lines} | awk -F',' '{print($1)}');
    if [[ ${projectId} == "project_id" ]];then
      echo "${lines},roles,parentData,billing,owners-viewers" > "${FILE_OUT}";
      continue;
    else
      local parentId=$(echo ${lines} | awk -F',' '{print($4)}');
      local parentType=$(echo ${lines} | awk -F',' '{print($5)}');
      local parentData=$(getOrgFold "${parentId}" "${parentType}");
      local roles=`gcloud projects get-iam-policy "${projectId}" --flatten=bindings --format="value(bindings.role)" --filter="bindings.members:${ACCOUNT_EMAIL}" || echo "NONE"`;
      local owners=`gcloud projects get-iam-policy "${projectId}" --flatten=bindings --format="value(bindings.members)" --filter="bindings.role:roles/owner OR bindings.role:roles/viewer" || echo "NONE"`;
      local billingData=`gcloud beta billing projects describe "${projectId}" --format="value(billingEnabled,billingAccountName)" || echo "NONE"`;
      [[ -z "${roles}" ]] && roles="FROM_ANY_PARENT" || roles="${roles}";

      echo "${lines},${roles},${parentData},${billingData},${owners}" >> "${FILE_OUT}";
    fi;
  done;
  echo "CSV exported in ${FILE_OUT}";
}

getProjects;

# script email limit
# ./self-project.sh "user@domain.com" "2"
