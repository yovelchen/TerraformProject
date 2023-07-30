#!/bin/bash
set -euo pipefail #script will fail quickly if there is an error and gets better outputs 

sudo apt-get update
sudo apt-get install -yq python3-pip
sudo apt install postgresql -y
sudo pip install psycopg2-binary flask

echo "installed all successfully" 

git clone https://github.com/Liorl14/Final_project #this is for now, will be changed to the new path when updated 

echo "git cloned successfully"

sudo chmod +x /var/lib/waagent/custom-script/download/0/terraform_exercise/Final_project/Terraform/flaskApp/flaskApp.py

# the crontab does not work yet... 
#sudo (crontab -l 2>/dev/null; echo "@reboot /usr/bin/python3 /var/lib/waagent/custom-script/download/0/Final_project/Terraform/flaskApp/flaskApp.py") | crontab -

#echo "inserted data to crontab successfully"

sudo python3 /var/lib/waagent/custom-script/download/0/Final_project/Terraform/flaskApp/flaskApp.py > output.log 2>&1 &

echo "python is running successfully"

#sudo reboot 
