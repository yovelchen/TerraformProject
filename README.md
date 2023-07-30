### Terraform Exercise solution  


### Installation  
To install the infrastructure, run the following commands in a terminal:  
    
    $ git clone https://github.com/yovelchen/TerraformProject.git
    
    $ cd terraform  

Create a file called "terraform.tfvars" that will contain the Postgresql password:  
*replace {password} with a password of your choice*
    
    $ echo db_password = {password} > terraform.tfvars   

Then, open a PowerShell/CMD terminal in the terraform directory and run the following commands:  
    
    $ terraform init  
    
    $ terraform plan  
    
    $ terraform apply

![architecture](https://github.com/yovelchen/azureProject/blob/main/map.png)
