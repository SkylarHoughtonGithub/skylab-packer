#!/bin/bash
export PKR_VAR_proxmox_token=$(aws ssm get-parameter --region us-east-2 --name "/proxmox/terraform_provider_token" --with-decryption --query 'Parameter.Value' --output text)

echo "Initializing packer..."
packer init almalinux10.pkr.hcl

echo "Validating Packer configuration..."
packer validate almalinux10.pkr.hcl

if [ $? -eq 0 ]; then
    echo "Configuration is valid!"
    
    # Build the template using SSM parameters
    echo "Starting Packer build with SSM parameters..."
    

    # Packer will automatically resolve SSM parameters from the template
    packer build almalinux10.pkr.hcl
    
fi
