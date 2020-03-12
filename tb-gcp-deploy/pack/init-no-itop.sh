#!/bin/bash
# Copyright 2019 The Tranquility Base Authors
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -o pipefail

echo User: $(whoami)
pwd
ls -al
echo "TB repo:"
ls -al repo/

# backup .gitignore file
cp repo/.gitignore .gitignore
cd repo/
# remove autogenerated folders
find -type d -name .git -exec rm -rf {} +
find -type d -name .idea -exec rm -rf {} +
find -type d -name .terraform -exec rm -rf {} +
find -type d -name .gcloud -exec rm -rf {} +
# find -type d -name nnpm install -g @angular/cliode_modules -exec rm -rf {} +
# remove autogenerated files
find -type f -name .gitignore -delete
find -type f -name clash.log -delete
find -type f -name *.tfstate -delete
find -type f -name *.tfstate.* -delete
find -type f -name *.out -delete
find -type f -name *.bak -delete
find -type f -name *.old -delete
# rm -rf **/.git **/.gitignore **/.idea **/.terraform **/.gcloud **/*.tfstate **/*.tfstate.* **/clash.log **/*.out **/*.bak **/*.old
cd ..
# put the .gitignore file from the backup into the root repo folder
mv .gitignore repo/


# install and configure stackdriver logging agent
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
bash ./install-logging-agent.sh
cat <<EOF > /etc/google-fluentd/config.d/bootstrap-log.conf
<source>
    @type tail
    # Format 'none' indicates the log is unstructured (text).
    format none
    # The path of the log file.
    path /var/log/bootstrap.log
    # The path of the position file that records where in the log file
    # we have processed already. This is useful when the agent
    # restarts.
    pos_file /var/lib/google-fluentd/pos/bootstrap-log.pos
    read_from_head true
    # The log tag for this log input.
    tag bootstrap-log
</source>
EOF
systemctl restart google-fluentd

# install Terraform 0.11
wget https://releases.hashicorp.com/terraform/0.12.9/terraform_0.12.9_linux_amd64.zip
apt-get -y update
apt-get -y install unzip
apt-get -y install zip
apt-get -y install nodejs
apt-get -y install git
apt-get -y install kubectl
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
apt-get -y install build-essential nodejs
npm install -g @angular/cli

node -v
npm -v

unzip -d /usr/local/bin/ terraform_0.12.9_linux_amd64.zip
rm terraform_0.12.9_linux_amd64.zip

# install kubectl ?
#export HOME=/root
#apt-get install -y kubectl

# move TB Repo files from packer's home directory to target /opt/tb/repo directory
mkdir -p /opt/tb
mv repo /opt/tb/
mv tb-gcp-tr /opt/tb/repo

# Build self service portal ui angular app
cd /opt/tb/repo/tb-self-service-portal-ui/

sudo npm install
sudo npm run build --prod

#Navigate to Landing Zone working dir
cd /opt/tb/repo/tb-gcp-tr/landingZone/no-itop/
# Download required terraform providers
terraform init -backend=false
pwd