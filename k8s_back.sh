#/bin/bash

echo "Este script HARÁ BACKUP K8S
Presione cualquier tecla para continuar...";

# Define variables
OUTPUT_DIR="./backup";
mkdir -p ${OUTPUT_DIR};
rm -rf ${OUTPUT_DIR}/*;

# Lista todos los Resource Definitions
RESOURCES=$(kubectl api-resources -o name);

# Itera sobre los Resource Definitions y descarga la configuración YAML de cada recurso
for RESOURCE in ${RESOURCES};do
  if [[  "${RESOURCE}" == "bindins" ]];then
    RESOURCE="rolebinding,clusterrolebinding";
  fi;
  echo "Try no namespace Resource: ${RESOURCE}";
  kubectl get ${RESOURCE} -o yaml > "${OUTPUT_DIR}/${RESOURCE}.yaml";
  echo "Try whit namespace Resource: ${RESOURCE}";
  kubectl get ${RESOURCE} -o yaml --all-namespaces >> "${OUTPUT_DIR}/${RESOURCE}.yaml";    
done;

# Comprime los archivos YAML descargados en un solo archivo
tar -czvf "${OUTPUT_DIR}.tgz" "${OUTPUT_DIR}";
