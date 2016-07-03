@echo off

echo --------------------------------------------
echo              Without API key
echo --------------------------------------------

call patchkit-tools app-versions-status --secret dba44b4d551b5be4f94c14342528e1e80d175e3edbe19781adc8416cbbd0bb4c

echo --------------------------------------------
echo              With API key
echo --------------------------------------------

call patchkit-tools app-versions-status --secret dba44b4d551b5be4f94c14342528e1e80d175e3edbe19781adc8416cbbd0bb4c --apikey 720459f3a4deb79f1b822194fc5de450
