curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2
ollama run qwen3-coder


ollama serve                    # start Ollama (if not already running)
ollama pull qwen3-coder:30b     # get the model (~18GB, one time)
ollama list                     # see installed models




# For creating container
for i in {1..10}; do docker run -d --name "my-container-$i" nginx; done

# for python environment.

apt install python3.10-venv   # To install Python3.10-venv package
python3 -m venv venv            # create a virtualenv
source venv/bin/activate
pip install -r requirements.txt # install LangChain + Ollama bindings

python3 agent.py                 # run the agent


# to show status
time docker stats
docker stats --no-stream


https://kind.sigs.k8s.io/docs/user/quick-start/

kind create cluster --config kind-config.yaml --name ai-kind-cluster

To install kind (Kubernetes in Docker) on Ubuntu, you must download the pre-built Linux binary, make it executable, and move it to your system path. Because kind runs Kubernetes clusters inside Docker containers, you also need Docker and kubectl installed on your system.Follow these steps to complete the entire setup:1. Install Prerequisiteskind requires an active Docker installation. If you do not have Docker or kubectl yet, run the following commands:bash# Update package list
sudo apt update

# Install Docker
sudo apt install docker.io -y

# Add your user to the docker group so you don't need 'sudo' for every command
sudo usermod -aG docker ${USER}

# Install kubectl (the Kubernetes CLI tool)
sudo snap install kubectl --classic
Use code with caution.Note: If you just added your user to the Docker group, log out and log back in (or run newgrp docker) for the group permissions to take effect.2. Download and Install kindRun this sequence of commands to download the latest stable Linux binary from the Official kind Release Page and move it to /usr/local/bin:bash# Detect architecture and download the matching stable binary
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://k8s.io
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://k8s.io

# Make the binary executable
chmod +x ./kind

# Move it to your execution path
sudo mv ./kind /usr/local/bin/kind
Use code with caution.3. Verify the InstallationCheck that kind is working correctly by outputting its version details:bashkind version
Use code with caution.4. Create Your First Local ClusterOnce verified, you can immediately spin up a local Kubernetes cluster using the create command:bashkind create cluster
Use code with caution.After the cluster finishes bootstrapping, test your connection with kubectl to confirm your local environment is fully operational:bashkubectl cluster-info
Use code with caution.If you ever want to destroy the local cluster and free up your system resources, you can remove it just as quickly:bashkind delete cluster
Use code with caution.


dc-ops@terraform:~/Learn-AI-MCP_ML/05-RND/AI-Powered-masterclass$ kind create cluster --config kind-config.yaml --name ai-kind-cluster
Creating cluster "ai-kind-cluster" ...
 ✓ Ensuring node image (kindest/node:v1.36.1) 🖼 
 ✓ Preparing nodes 📦 📦 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
 ✓ Joining worker nodes 🚜 
Set kubectl context to "kind-ai-kind-cluster"
You can now use your cluster with:

kubectl cluster-info --context kind-ai-kind-cluster

Thanks for using kind! 😊
dc-ops@terraform:~/Learn-AI-MCP_ML/05-RND/AI-Powered-masterclass$ kubectl cluster-info --context kind-ai-kind-cluster
Command 'kubectl' not found, but can be installed with:
sudo snap install kubectl
dc-ops@terraform:~/Learn-AI-MCP_ML/05-RND/AI-Powered-masterclass$ sudo snap install kubectl
error: This revision of snap "kubectl" was published using classic confinement and thus may perform
       arbitrary system changes outside of the security sandbox that snaps are usually confined to,
       which may put your system at risk.

       If you understand and want to proceed repeat the command including --classic.
dc-ops@terraform:~/Learn-AI-MCP_ML/05-RND/AI-Powered-masterclass$ sudo snap install kubectl --classic

