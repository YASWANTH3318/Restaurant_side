@echo off
echo Deploying Firestore rules...
firebase deploy --only firestore:rules
echo Rules deployed successfully!
pause
