# iOS-Universal-Framework-Script
Script to generate universal framework script

Add this script to :
1. Go to Edit Scheme..
2. Click Build and Expand it
3. Choose Post-actions
4. Change Provide build settings from to your library project
5. Copy paste the script

For Objective-C Framework, if you put config inside PREPROCESSOR MACRO, you can use change config to this code

CONFIG="$GCC_PREPROCESSOR_DEFINITIONS"
