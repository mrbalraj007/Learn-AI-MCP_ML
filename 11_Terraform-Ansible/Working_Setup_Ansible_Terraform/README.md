# **End-to-End Terraform + Ansible + AWS Dynamic Inventory Setup**

You want a professional production-style setup where:

**Terra-1 VM**
Runs Terraform
Creates AWS EC2 instances
Tags instances properly
Generates SSH keys
Triggers Ansible automatically
Ans-1 VM
Runs Ansible
Uses AWS Dynamic Inventory
Automatically discovers EC2 instances
Installs:
Docker
kubectl
kind
curl
unzip
tmux
Fully automated
Modular Terraform structure
Reusable globally

This is the correct enterprise-grade approach.

# HIGH LEVEL DESIGN

```sh
terra-1
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   ├── modules/
│   │   └── ec2/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│
└── ansible-trigger.sh

ans-1
│
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── aws_ec2.yml
│   ├── playbooks/
│   │   └── install-tools.yml
│   └── group_vars/
```

```sh
mkdir -p terra-1/terraform/modules/ec2 && \
touch terra-1/terraform/{main.tf,variables.tf,outputs.tf,provider.tf,terraform.tfvars} && \
touch terra-1/terraform/modules/ec2/{main.tf,variables.tf,outputs.tf} && \
touch terra-1/ansible-trigger.sh
```
```sh
mkdir -p ans-1/ansible/{inventory,playbooks,group_vars} && \
touch ans-1/ansible/ansible.cfg && \
touch ans-1/ansible/inventory/aws_ec2.yml && \
touch ans-1/ansible/playbooks/install-tools.yml
```
**STEP 1 — AWS IAM REQUIREMENTS**

Create an IAM User:

Example:
```sh
terraform-ansible-user
```
**Attach policies:**

- AmazonEC2FullAccess
- IAMReadOnlyAccess

OR preferably create least-privileged policies later.

Generate:

- Access Key
- Secret Key
  
**STEP 2 — PREPARE TERRA-1 VM**

Install Terraform.

- Install Terraform

**On Terra-1:**
```sh
sudo apt update
sudo apt install -y unzip curl
```
**Install Terraform:**

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository \
"deb https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt update
sudo apt install terraform -y

**Verify:**
```sh
terraform version
```

**STEP 3 — PREPARE ANS-1 VM**

**Install Ansible + boto3.**
```sh
sudo apt update

sudo apt install -y \
python3-pip \
ansible \
jq \
curl \
git \
unzip

pip3 install boto3 botocore

ansible-galaxy collection install amazon.aws
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix

```

**Verify Collection Installed**

Run:
```sh
ansible-galaxy collection list | grep amazon.aws
```
Verify:
ansible --version

# Verify Dynamic Inventory Plugin
ansible-doc -t inventory amazon.aws.aws_ec2

<!-- # Install Additional Recommended Collections

Professional environments usually install these too:

ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix -->


**STEP 4 — CONFIGURE AWS CLI ON BOTH VMS**

Install AWS CLI.
```sh
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip

unzip awscliv2.zip

sudo ./aws/install
```

**Configure:**

```sh
aws configure

Enter:

Access Key
Secret Key
Region
json
```
Do this on:

- Terra-1
- Ans-1



**STEP 5 — CONFIGURE SSH ACCESS**

**Copy private key to Ans-1:**

From Terra-1:
```sh
scp devtools-key.pem ansible@ANSIBLE_SERVER_IP:/home/ansible/.ssh/

On Ans-1:

chmod 400 ~/.ssh/devtools-key.pem
```
**Update ansible.cfg:**
```sh
private_key_file = ~/.ssh/devtools-key.pem
```

**STEP 6 — Create .ssh Directory on Ans-1**

**SSH into Ans-1:**
```sh
ssh dc-ops@192.168.1.212
```
Now create .ssh directory:

mkdir -p ~/.ssh
chmod 700 ~/.ssh

Verify:

ls -ld ~/.ssh

Expected:

drwx------ 2 dc-ops dc-ops
STEP 2 — Exit Ans-1
exit

STEP 3 — Copy Key Properly

Now from Terra-1:

scp devtools-key.pem dc-ops@192.168.1.212:/home/dc-ops/.ssh/

OR simpler:

scp devtools-key.pem dc-ops@192.168.1.212:~/.ssh/

STEP 4 — Set Proper Permissions on Ans-1

SSH again:

ssh dc-ops@192.168.1.212

Run:

chmod 400 ~/.ssh/devtools-key.pem

**STEP 2 — INSTALL REQUIRED PACKAGES**
```sh
sudo apt update

sudo apt install -y \
python3-pip \
python3-venv \
git \
curl \
unzip
```
**STEP 3 — CREATE PYTHON VENV (BEST PRACTICE)**
```sh
mkdir -p ~/ansible-venv

python3 -m venv ~/ansible-venv

Activate:

source ~/ansible-venv/bin/activate

You should now see:

(ansible-venv)
```

**STEP 4 — INSTALL LATEST ANSIBLE**
```sh
pip install --upgrade pip

pip install ansible boto3 botocore
```

**STEP 5 — INSTALL AMAZON COLLECTION**
```sh
ansible-galaxy collection install amazon.aws
```

**STEP 6 — VERIFY VERSION**
```sh
Run:

ansible --version

You should see something like:

ansible [core 2.18.x]
```

**VERY IMPORTANT.**

IMPORTANT PROFESSIONAL NOTE

Always activate venv before using Ansible:

`source ~/ansible-venv/bin/activate`

You can automate this:

```sh
Add to ~/.bashrc

echo 'source ~/ansible-venv/bin/activate' >> ~/.bashrc

Then reload:

source ~/.bashrc
```

**Install pywinrm package**
```sh
ssh 192.168.1.212 "source ~/ansible-venv/bin/activate && pip install pywinrm"```

# Command

```sh
ansible-inventory -i inventory/aws_ec2.yml --list
ansible-inventory -i inventory/aws_ec2.yml --graph
```

Step 2: If NO key exists → create one
ssh-keygen -t rsa -b 4096 -C "dc-ops"

Press ENTER for defaults.

🔥 Step 3: Copy public key to target server
Option A (best & easiest)
ssh-copy-id dc-ops@192.168.1.212


# Verify command at Ansible Server
```sh
ansible-playbook playbooks/install-tools.yml
ansible-inventory --list
ansible-inventory --graph
```

rsync -avzP dc-ops@192.168.1.212:/home/dc-ops/ans-1 .
