# Variables - Ensure these match your provisioning script
DOMAIN="yourdomain.com"
PROJECT_ID="your-project-id"
LOCATION="global"

echo "Starting cleanup for 30 temporary users..."

# 1. UNASSIGN GEMINI LICENSES
# We send an empty list and set deleteUnassignedUserLicenses to true
# This clears the license store for the project
echo "Unassigning Gemini Enterprise licenses..."
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: $PROJECT_ID" \
  "https://$LOCATION-discoveryengine.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/userStores/default_user_store:batchUpdateUserLicenses" \
  -d "{
    \"inlineSource\": {
      \"userLicenses\": []
    },
    \"updateMask\": {
      \"paths\": [\"userPrincipal\", \"licenseConfig\"]
    },
    \"deleteUnassignedUserLicenses\": true
  }"

# 2. DELETE CLOUD IDENTITY USERS
for i in {1..30}
do
   USER_EMAIL="temp-user-$i@$DOMAIN"
   echo "Deleting $USER_EMAIL..."
   gcloud identity users delete "$USER_EMAIL" --quiet
done

echo "Cleanup complete. 30 users and their Gemini licenses have been removed."