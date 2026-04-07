# Variables
DOMAIN="yourdomain.com"
PROJECT_ID="your-project-id"
LOCATION="global"
SUBSCRIPTION_ID="your-subscription-id"

echo "Email,Password" > temp_users_credentials.csv

USER_LIST_JSON=""

for i in {1..30}
do
   USER_EMAIL="temp-user-$i@$DOMAIN"
   # Generate a random 16-char password
   PASSWORD=$(openssl rand -base64 12)
   
   echo "Creating $USER_EMAIL..."
   
   # 1. Create the User in Cloud Identity
   gcloud identity users create "$USER_EMAIL" \
       --display-name="Temp User $i" \
       --password="$PASSWORD" --quiet
   
   # 2. Append to credential file
   echo "$USER_EMAIL,$PASSWORD" >> temp_users_credentials.csv
   
   # 3. Build the JSON string for the License API
   USER_LIST_JSON+="{\"userPrincipal\":\"$USER_EMAIL\",\"licenseConfig\":\"projects/$PROJECT_ID/locations/$LOCATION/subscriptions/$SUBSCRIPTION_ID\"},"
done

# Remove trailing comma
USER_LIST_JSON=${USER_LIST_JSON%?}

# 4. Batch Assign Gemini Enterprise Licenses
echo "Assigning Gemini Enterprise licenses..."
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: $PROJECT_ID" \
  "https://$LOCATION-discoveryengine.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/userStores/default_user_store:batchUpdateUserLicenses" \
  -d "{
    \"inlineSource\": {
      \"userLicenses\": [$USER_LIST_JSON],
      \"updateMask\": {
        \"paths\": [\"userPrincipal\", \"licenseConfig\"]
      }
    },
    \"deleteUnassignedUserLicenses\": false
  }"

echo "Done! Credentials saved to temp_users_credentials.csv"