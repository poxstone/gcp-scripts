BILLING_ACCOUNT="${1}";
PROJECTS_ID="${@}";

function trimBillingString {
  echo "${1}" | sed 's/billingAccounts\///';
}

for project in ${PROJECTS_ID[@]};do
  # Omite billing parameter
  if [[ "${project}" == "${BILLING_ACCOUNT}" ]]; then continue; fi;
  # Get current billing info
  printf "\n";
  billing_status=(`gcloud beta billing projects describe "${project}" --format="value(billingEnabled,billingAccountName)"`);
  echo project=${project},billing_enable=${billing_status[0]},current_billing=${billing_status[1]};
  # Set new billing account
  gcloud beta billing projects link "${project}" --billing-account=`trimBillingString ${BILLING_ACCOUNT}`;
done;

# ./addbilling.sh 010662-B132AF-22EB19 test01-billing-add