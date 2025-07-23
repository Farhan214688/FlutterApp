# Deployment Instructions

## Deploy Firestore Rules

To fix the permissions issue, you need to deploy the updated Firestore security rules. Follow these steps:

1. Open Firebase Console: https://console.firebase.google.com
2. Select your project: `rapit-777d7`
3. In the left sidebar, click on "Firestore Database"
4. Click on the "Rules" tab
5. Replace the entire content with the updated rules from `firestore.rules` 
6. Click "Publish" to deploy the rules

## Create Required Indexes

Your application requires several indexes to function properly:

1. Follow the instructions in `README_INDEXES.md` to create the required indexes

## Verify Admin Permissions

Make sure your admin account is properly set up:

1. In Firebase Console, navigate to Firestore Database
2. Open the `users` collection
3. Find your admin user document
4. Verify it has a field `type` with value `"admin"`

If the `type` is not set correctly:
1. Click on the document to edit it
2. Add/edit the field `type` and set its value to `"admin"`
3. Save the changes

## Testing

After deploying the rules and creating the indexes:

1. Restart your app completely
2. Log out and log back in as admin
3. Navigate to the Profiles screen
4. Both customers and professionals should now be visible

## Troubleshooting

If you still face issues:

1. Check Firebase Authentication Console to ensure your admin user is properly authenticated
2. Examine the Firestore Rules in Firebase Console and make sure they match `firestore.rules`
3. Look at the app logs for any error messages
4. Verify that the `isAdmin()` function in the security rules correctly identifies your admin user 