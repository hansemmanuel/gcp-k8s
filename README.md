# gcp-k8s
Repository contains terraform scripts to quickly deploy k8s manager node and worker nodes in GCP with firewall rules and vpc , then ansible play for installing k8s on these nodes.

The purpose of these terraform and ansible scripts are to quickly deploy a self managed kubernetes cluster in GCP for testing purpose. The terraform and ansible scripts can easily extended to deploy multiple K8s cluster.  By default it will setup a K8s cluster with single master node and a single worker node.

**How to run**

First get into folder 'terraform'. and copy  'variables.tf.example'   as 'variables.tf'.  define the variables as per your environment .
then init the terraform first

    terraform init 

Then run the 'plan' and lookout for any errors

    terraform plan

Finally apply it

    terraform apply

Verify if all GCP resources are deployed successfully

Then verify ansible folder have correct inventory file 'k8s-cluster1-inventory'  get auto generated  by terraform.
if all good, run the ansible play.  Ansible role used to install kubernetes cluster is derived from here https://github.com/geerlingguy/ansible-role-kubernetes with minimal changes. So many modification can be done via vars as per the requirement.

install the dependency

    ansible-galaxy install geerlingguy.docker

Run the playbook, check playbook for some vars and change it if needed

    ansible-playbook -i k8s-cluster1-inventory k8s_playbook.yml

It will create K8s cluster on nodes defined in inventory. By default it will deploy the calico CNI with IPIP overlay network. But it can be adjusted as mentioned at https://github.com/geerlingguy/ansible-role-kubernetes . It will also install **callicoctl**.


**How to deploy more nodes and clusters**

Number of worker nodes in a k8s cluster can be adjusted by adding more compute resource in terraform main.tf and editing the resource "local_file" "ansible_inventory" block and 'inventory.tmpl' file respectively.

Some times we need to deploy more than one K8s cluster at the same time for testing something like consul service mesh across multiple k8 clusters . Terraform main.tf can be easily extended to achieve the same. An example tf file  'main_two_k8s_clusters.tf.example'   added into the repo as an example. In this case there will be two ansible inventory files will be created and need to run play with each of them separately .


