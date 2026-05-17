#!/bin/bash
# ============================================
# Post-Deployment Verification Script
# File: verify_deployment.sh
# 
# Purpose: Verify all components are working correctly
# Usage: bash verify_deployment.sh
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_header() { echo -e "${BLUE}========== $1 ==========${NC}"; }

print_header "Post-Deployment Verification"
echo ""

# Counter for results
passed=0
failed=0

# Function to check command existence
check_command() {
    local cmd=$1
    local name=$2
    
    if command -v $cmd &> /dev/null; then
        print_status "$name is installed"
        ((passed++))
    else
        print_error "$name is NOT installed"
        ((failed++))
    fi
}

# Function to check Ansible connectivity
check_ansible_connectivity() {
    local inventory=$1
    
    if [ ! -f "$inventory" ]; then
        print_error "Inventory file not found: $inventory"
        ((failed++))
        return
    fi
    
    print_header "Testing Ansible Connectivity"
    
    if ansible all -i "$inventory" -m ping -o 2>/dev/null | grep -q "SUCCESS"; then
        print_status "All hosts are reachable via Ansible"
        ((passed++))
    else
        print_warning "Some hosts may not be reachable"
        ((failed++))
    fi
}

# Function to check EC2 instance status
check_ec2_status() {
    print_header "Checking EC2 Instance Status"
    
    if ! command -v aws &> /dev/null; then
        print_warning "AWS CLI not installed, skipping EC2 status check"
        return
    fi
    
    instances=$(aws ec2 describe-instances --query 'Reservations[0].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output text)
    
    if [ -z "$instances" ]; then
        print_warning "No EC2 instances found"
        ((failed++))
    else
        echo "$instances" | while read instance_id state ip; do
            if [ "$state" = "running" ]; then
                print_status "Instance $instance_id is running (IP: $ip)"
                ((passed++))
            else
                print_error "Instance $instance_id is in state: $state"
                ((failed++))
            fi
        done
    fi
}

# Function to verify package installations on EC2
verify_packages_on_ec2() {
    local inventory=$1
    
    print_header "Verifying Package Installations"
    
    if [ ! -f "$inventory" ]; then
        print_warning "Inventory file not found, skipping package verification"
        return
    fi
    
    packages=("docker" "kubectl" "kind" "curl" "tmux" "unzip")
    
    for package in "${packages[@]}"; do
        case $package in
            docker)
                cmd="docker --version"
                ;;
            *)
                cmd="which $package"
                ;;
        esac
        
        if ansible all -i "$inventory" -m shell -a "$cmd" -o 2>/dev/null | grep -q "SUCCESS\|found"; then
            print_status "$package is installed on EC2 instances"
            ((passed++))
        else
            print_warning "$package might not be installed"
            ((failed++))
        fi
    done
}

# Function to check file permissions
check_file_permissions() {
    print_header "Checking File Permissions"
    
    if [ -f ~/.ssh/terraform_ec2_key ]; then
        perms=$(stat -c %a ~/.ssh/terraform_ec2_key)
        if [ "$perms" = "600" ]; then
            print_status "SSH private key has correct permissions (600)"
            ((passed++))
        else
            print_error "SSH private key has incorrect permissions ($perms, should be 600)"
            ((failed++))
        fi
    else
        print_warning "SSH private key not found"
    fi
}

# Main verification flow
echo "Starting verification checks..."
echo ""

# Check Terraform (if on Terra-1)
if [ -d "$HOME/terraform" ]; then
    print_header "Checking Terraform Setup"
    check_command "terraform" "Terraform"
    check_command "aws" "AWS CLI"
    check_file_permissions
fi

# Check Ansible (if on Ans-1)
if [ -d "$HOME/ansible" ]; then
    print_header "Checking Ansible Setup"
    check_command "ansible" "Ansible"
    check_command "python3" "Python3"
    
    # Check inventory
    if [ -f "$HOME/ansible/inventory/inventory.json" ]; then
        print_status "Inventory file found"
        ((passed++))
    else
        print_error "Inventory file not found"
        ((failed++))
    fi
    
    # Test connectivity
    check_ansible_connectivity "$HOME/ansible/inventory/inventory.json"
    
    # Verify packages
    verify_packages_on_ec2 "$HOME/ansible/inventory/inventory.json"
fi

# Summary
echo ""
print_header "Verification Summary"
echo -e "Passed: ${GREEN}$passed${NC}"
echo -e "Failed: ${RED}$failed${NC}"
echo ""

if [ $failed -eq 0 ]; then
    print_status "All verifications passed!"
    exit 0
else
    print_error "Some verifications failed. Please check the errors above."
    exit 1
fi
