# RUN FUNCTIONS

## 1. addPolicyToBilling.sh
| **Note**: With admin Org. or owner project. 

- Permissions to Projects:
- Change billing to each project: `./addPolicyToBilling.sh [USER_BILLING] [PROJECT-ID-01 PROJECT_ID-02...]`
```bash
./addPolicyToBilling.sh my-billing-adminuser@mail.com gcp-project-1 gcp-project-2 gcp-project-3 >> billing-permissions.txt;
```
- Permissions to Organization:
```bash
./addPolicyToBilling.sh my-billing-adminuser@mail.com my-org-domain.com >> billing-permissions.txt;
```

## 2. addBilling.sh
| **Note**: "my-billing-adminuser@mail.com"

- Change billing to each project: `./addBilling.sh [BILLING_ID] [PROJECT-ID-01 PROJECT_ID-02...]`
```bash
./addBilling.sh 010000-A111AA-22BB22 gcp-project-1 gcp-project-2 gcp-project-3 >> billing-facturation.txt;
```

## 3. get_iam_permissions.sh

- create folders with permissions
```bash
./get_iam_permissions.sh;
ls organizations;
ls projects;
ls folders;
```

## 4. self-projects.sh

- get all user project and roles (csv): `./self-projects.sh [USER_EMAIL] [NUM_LIMIT_PROJECTS]`
```bash
./self-projects.sh;

- Lo anterior demorará entre 5min y 1hora dependiendo la cantidad de proyectos a los que se tenga accesos.
- Al finalizar dejará un archivo "**projects_roles_[USER_EMAIL].csv**" para descargar y posteriormente analizar.
- La información de dicho archivo contiene las siguientes columnas:
  - **project_id**: 
  - **project_name**: 
  - **project_number**: 
  - **parent_id**: 
  - **parent_type**: 
  - **project_create_time**: 
  - **project_lifecycle_state**: 
  - **my_project_roles**: 
  - **parent_data_info**: 
  - **project_billing_info**: 
  - **project_all_roles**: 

# optional
./self-projects.sh "name@domain.com" "20";
```
