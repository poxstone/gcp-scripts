# RUN FUNCTIONS

## 1. addPolicyToBilling.sh
| **Note**: With admin Org. or owner project. 

- Permissions to Projects:
- Change billing to each project: `./addPolicyToBilling.sh` `[USER_BILLING]` `[PROJECT-ID-01 PROJECT_ID-02...]`
```bash
./addPolicyToBilling.sh my-billing-adminuser@mail.com gcp-project-1 gcp-project-2 gcp-project-3 >> billing-permissions.txt;
```
- Permissions to Organization:
```bash
./addPolicyToBilling.sh my-billing-adminuser@mail.com my-org-domain.com >> billing-permissions.txt;
```

## 2. addBilling.sh
| **Note**: "my-billing-adminuser@mail.com"

- Change billing to each project: `./addBilling.sh` `[BILLING_ID]` `[PROJECT-ID-01 PROJECT_ID-02...]`
```bash
./addBilling.sh 010000-A111AA-22BB22 gcp-project-1 gcp-project-2 gcp-project-3 >> billing-facturation.txt;
```
