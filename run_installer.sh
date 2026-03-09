#!/bin/bash
cd "/mnt/c/Users/Dhairya Limbani/OneDrive/Documents/dcpanel/extracted_cpanel"
perl install --force > /var/log/cpanel_run.log 2>&1 &
echo "Installer started in background with PID $!"
