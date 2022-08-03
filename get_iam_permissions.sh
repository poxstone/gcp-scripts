#!/bin/bash
mkdir -p organizations projects folders;

# get recursive folders 
function getFolders {
  local folder="${1}";
  local folders_list=`gcloud resource-manager folders list --folder="${folder}" --format="value(name)"`;
  echo "> ${folder}";
  if [[ "${folders_list}" != "" ]];then
    for folder_l in $(echo $folders_list);do
      if [[ "${folder_l}" != "" ]];then
        # get permissios
        gcloud resource-manager folders get-iam-policy "${folder_l}" --format "json" > "folders/${folder_l}.json" && \
        getFolders "${folder_l}";
      fi;
    done;
  fi;
}

# get projects permissions
for project in `gcloud projects list --format="value(projectId)"`;do
  gcloud projects get-iam-policy "${project}" --format "json" > "projects/${project}.json";
done;

# get organizations and folders permissions
for organization in `gcloud organizations list --format="value(name)"`;do
  # get root folders
  gcloud organizations get-iam-policy "${organization}" --format "json" > "organizations/${organization}.json";
  folders_root=`gcloud resource-manager folders list --organization="${organization}" --format="value(name)"`;

  if [[ "${folders_root}" != "" ]];then
    for folder_r in $(echo $folders_root);do
      if [[ "${folder_r}" != "" ]];then
        # get permissios and recursive folders
        gcloud resource-manager folders get-iam-policy "${folder_r}" --format "json" > "folders/${folder_r}.json" && \
        getFolders "${folder_r}";
      fi;
    done;
  fi;

done;
