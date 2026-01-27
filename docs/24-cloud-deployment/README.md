# 24 - Cloud Deployment

## Table of Contents

1. [Cloud Deployment Overview](#cloud-deployment-overview)
2. [AWS Deployment](#aws-deployment)
3. [Azure Deployment](#azure-deployment)
4. [Google Cloud Platform](#google-cloud-platform)
5. [Hybrid Cloud Architecture](#hybrid-cloud-architecture)
6. [Cloud Security Considerations](#cloud-security-considerations)

---

## Cloud Deployment Overview

### Cloud Deployment Models

```
+==============================================================================+
|                   WALLIX CLOUD DEPLOYMENT OPTIONS                            |
+==============================================================================+

  DEPLOYMENT MODELS
  =================

  +------------------------------------------------------------------------+
  |                                                                        |
  | MODEL 1: CLOUD-HOSTED (IaaS)                                           |
  | ============================                                           |
  |                                                                        |
  |   * WALLIX Bastion runs on cloud VMs                                   |
  |   * Customer manages the PAM infrastructure                            |
  |   * Full control over configuration                                    |
  |   * Supports AWS EC2, Azure VMs, GCP Compute Engine                    |
  |                                                                        |
  |   +----------------+     +----------------+     +----------------+      |
  |   |    AWS EC2     |     |   Azure VM     |     |   GCP CE       |      |
  |   |                |     |                |     |                |      |
  |   |  +---------+   |     |  +---------+   |     |  +---------+   |      |
  |   |  | WALLIX  |   |     |  | WALLIX  |   |     |  | WALLIX  |   |      |
  |   |  | Bastion |   |     |  | Bastion |   |     |  | Bastion |   |      |
  |   |  +---------+   |     |  +---------+   |     |  +---------+   |      |
  |   |                |     |                |     |                |      |
  |   +----------------+     +----------------+     +----------------+      |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  | MODEL 2: MARKETPLACE IMAGE                                             |
  | ==========================                                             |
  |                                                                        |
  |   * Pre-configured WALLIX image from cloud marketplace                 |
  |   * Faster deployment, tested configuration                            |
  |   * Subscription or BYOL licensing                                     |
  |                                                                        |
  |   AWS Marketplace: WALLIX Bastion Enterprise                           |
  |   Azure Marketplace: WALLIX Bastion                                    |
  |   GCP Marketplace: WALLIX Bastion (check availability)                 |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  | MODEL 3: HYBRID (On-Prem + Cloud)                                      |
  | =================================                                      |
  |                                                                        |
  |   * Primary Bastion on-premises                                        |
  |   * Cloud Bastion for cloud workloads                                  |
  |   * Centralized management                                             |
  |                                                                        |
  |   +----------------+                    +----------------+             |
  |   |  ON-PREMISES   |     VPN/          |     CLOUD      |             |
  |   |                | Direct Connect    |                |             |
  |   |  +---------+   |<----------------->|  +---------+   |             |
  |   |  | WALLIX  |   |                   |  | WALLIX  |   |             |
  |   |  | Primary |   |                   |  | Cloud   |   |             |
  |   |  +---------+   |                   |  +---------+   |             |
  |   |       |        |                   |       |        |             |
  |   |  [On-prem      |                   |  [Cloud        |             |
  |   |   targets]     |                   |   targets]     |             |
  |   +----------------+                   +----------------+             |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## AWS Deployment

### AWS Architecture

```
+==============================================================================+
|                   AWS DEPLOYMENT ARCHITECTURE                                |
+==============================================================================+

                          +------------------+
                          |    INTERNET      |
                          +--------+---------+
                                   |
                          +--------+---------+
                          |   AWS Region     |
                          |   (us-east-1)    |
  +------------------------+--------+--------+------------------------+
  |                                 |                                 |
  |                        +--------+---------+                       |
  |                        | Internet Gateway |                       |
  |                        +--------+---------+                       |
  |                                 |                                 |
  |  VPC (10.0.0.0/16)              |                                 |
  |  +------------------------------+------------------------------+  |
  |  |                              |                              |  |
  |  |  PUBLIC SUBNET (10.0.1.0/24) |  PUBLIC SUBNET (10.0.2.0/24) |  |
  |  |  Availability Zone A         |  Availability Zone B         |  |
  |  |  +------------------------+  |  +------------------------+  |  |
  |  |  |                        |  |  |                        |  |  |
  |  |  |  +------------------+  |  |  |  +------------------+  |  |  |
  |  |  |  | NAT Gateway      |  |  |  |  | NAT Gateway      |  |  |  |
  |  |  |  +------------------+  |  |  |  +------------------+  |  |  |
  |  |  |                        |  |  |                        |  |  |
  |  |  |  +------------------+  |  |  |  +------------------+  |  |  |
  |  |  |  | ALB / NLB        +--+--+--+  | (if multi-AZ)    |  |  |  |
  |  |  |  | (Load Balancer)  |  |  |  |  |                  |  |  |  |
  |  |  |  +------------------+  |  |  |  +------------------+  |  |  |
  |  |  |                        |  |  |                        |  |  |
  |  |  +------------------------+  |  +------------------------+  |  |
  |  |                              |                              |  |
  |  |  PRIVATE SUBNET (10.0.10.0/24)  PRIVATE SUBNET (10.0.20.0/24) |
  |  |  +------------------------+  |  +------------------------+  |  |
  |  |  |                        |  |  |                        |  |  |
  |  |  |  +------------------+  |  |  |  +------------------+  |  |  |
  |  |  |  | WALLIX Bastion   |  |  |  |  | WALLIX Bastion   |  |  |  |
  |  |  |  | Primary (EC2)    |  |  |  |  | Standby (EC2)    |  |  |  |
  |  |  |  | m5.xlarge        |  |  |  |  | m5.xlarge        |  |  |  |
  |  |  |  +--------+---------+  |  |  |  +--------+---------+  |  |  |
  |  |  |           |            |  |  |           |            |  |  |
  |  |  +------------------------+  |  +------------------------+  |  |
  |  |              |                              |                |  |
  |  |              +---------------+--------------+                |  |
  |  |                              |                               |  |
  |  |  +---------------------------+----------------------------+  |  |
  |  |  |                     SHARED SERVICES                    |  |  |
  |  |  |                                                        |  |  |
  |  |  |  +----------------+  +----------------+  +----------+  |  |  |
  |  |  |  | RDS PostgreSQL |  | EFS (Shared    |  | Secrets  |  |  |  |
  |  |  |  | (Multi-AZ)     |  |  Recordings)   |  | Manager  |  |  |  |
  |  |  |  +----------------+  +----------------+  +----------+  |  |  |
  |  |  |                                                        |  |  |
  |  |  +--------------------------------------------------------+  |  |
  |  |                                                              |  |
  |  +--------------------------------------------------------------+  |
  |                                                                    |
  +--------------------------------------------------------------------+

+==============================================================================+
```

### AWS EC2 Instance Sizing

```
+==============================================================================+
|                   AWS EC2 INSTANCE RECOMMENDATIONS                           |
+==============================================================================+

  +------------+----------------+-------+--------+---------------------------+
  | Deployment | Instance Type  | vCPU  | Memory | Use Case                  |
  +------------+----------------+-------+--------+---------------------------+
  | POC/Lab    | t3.large       | 2     | 8 GB   | Testing, evaluation       |
  | Small      | m5.xlarge      | 4     | 16 GB  | < 100 concurrent sessions |
  | Medium     | m5.2xlarge     | 8     | 32 GB  | 100-500 sessions          |
  | Large      | m5.4xlarge     | 16    | 64 GB  | 500-1000 sessions         |
  | Enterprise | m5.8xlarge     | 32    | 128 GB | 1000+ sessions            |
  +------------+----------------+-------+--------+---------------------------+

  STORAGE RECOMMENDATIONS
  =======================

  +------------------+------------------+-----------------------------------+
  | Volume           | Type             | Size                              |
  +------------------+------------------+-----------------------------------+
  | Root (OS)        | gp3              | 100 GB minimum                    |
  | Database         | gp3 or io2       | 200 GB+ (IOPS: 3000+)             |
  | Recordings       | gp3 or EFS       | 500 GB+ (depends on retention)    |
  +------------------+------------------+-----------------------------------+

  * Use EFS for shared recordings storage in HA deployments
  * Consider S3 for long-term recording archival

+==============================================================================+
```

### AWS Deployment Steps

```
+==============================================================================+
|                   AWS DEPLOYMENT PROCEDURE                                   |
+==============================================================================+

  STEP 1: NETWORK SETUP
  =====================

  # Create VPC
  aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=wallix-vpc}]'

  # Create subnets (public and private in each AZ)
  aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=wallix-public-1a}]'

  aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.10.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=wallix-private-1a}]'

  --------------------------------------------------------------------------

  STEP 2: SECURITY GROUPS
  =======================

  # WALLIX Bastion Security Group
  +------------------------------------------------------------------------+
  | Inbound Rules                                                          |
  +----------+----------+-----------------+--------------------------------+
  | Port     | Protocol | Source          | Description                    |
  +----------+----------+-----------------+--------------------------------+
  | 443      | TCP      | 0.0.0.0/0       | HTTPS (Web UI, API)            |
  | 22       | TCP      | User IPs        | SSH Proxy                      |
  | 3389     | TCP      | User IPs        | RDP Proxy                      |
  | 5432     | TCP      | Bastion SG      | PostgreSQL (HA sync)           |
  | 2049     | TCP      | Bastion SG      | EFS (shared storage)           |
  +----------+----------+-----------------+--------------------------------+

  | Outbound Rules                                                         |
  +----------+----------+-----------------+--------------------------------+
  | Port     | Protocol | Destination     | Description                    |
  +----------+----------+-----------------+--------------------------------+
  | 22       | TCP      | Target subnets  | SSH to targets                 |
  | 3389     | TCP      | Target subnets  | RDP to targets                 |
  | 443      | TCP      | 0.0.0.0/0       | HTTPS (updates, integrations)  |
  | 636      | TCP      | AD servers      | LDAPS                          |
  | 5432     | TCP      | RDS endpoint    | Database                       |
  +----------+----------+-----------------+--------------------------------+

  --------------------------------------------------------------------------

  STEP 3: RDS POSTGRESQL (for HA)
  ===============================

  aws rds create-db-instance \
    --db-instance-identifier wallix-db \
    --db-instance-class db.m5.large \
    --engine postgres \
    --engine-version 14 \
    --master-username wallix \
    --master-user-password <secure-password> \
    --allocated-storage 200 \
    --storage-type gp3 \
    --multi-az \
    --vpc-security-group-ids sg-xxx \
    --db-subnet-group-name wallix-db-subnet

  --------------------------------------------------------------------------

  STEP 4: EFS FOR RECORDINGS
  ==========================

  aws efs create-file-system \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --encrypted \
    --tags Key=Name,Value=wallix-recordings

  # Create mount targets in each AZ
  aws efs create-mount-target \
    --file-system-id fs-xxx \
    --subnet-id subnet-xxx \
    --security-groups sg-xxx

  --------------------------------------------------------------------------

  STEP 5: LAUNCH EC2 INSTANCE
  ===========================

  # Using WALLIX AMI from Marketplace or custom AMI
  aws ec2 run-instances \
    --image-id ami-wallix-xxx \
    --instance-type m5.xlarge \
    --key-name wallix-key \
    --security-group-ids sg-xxx \
    --subnet-id subnet-xxx \
    --iam-instance-profile Name=wallix-instance-profile \
    --block-device-mappings '[
      {"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":100,"VolumeType":"gp3"}},
      {"DeviceName":"/dev/sdb","Ebs":{"VolumeSize":200,"VolumeType":"gp3"}}
    ]' \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=wallix-primary}]'

  --------------------------------------------------------------------------

  STEP 6: POST-LAUNCH CONFIGURATION
  =================================

  # SSH to instance
  ssh -i wallix-key.pem admin@<instance-ip>

  # Mount EFS
  sudo mount -t efs fs-xxx:/ /var/wab/recorded

  # Configure external database
  sudo wab-admin config-db --host wallix-db.xxx.rds.amazonaws.com \
    --port 5432 --user wallix --password <password>

  # Initialize WALLIX
  sudo wab-admin init

  # Access web UI at https://<instance-ip>

+==============================================================================+
```

### AWS IAM Permissions

```
+==============================================================================+
|                   AWS IAM POLICY FOR WALLIX                                  |
+==============================================================================+

  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "SecretsManagerAccess",
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource": "arn:aws:secretsmanager:*:*:secret:wallix/*"
      },
      {
        "Sid": "KMSAccess",
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        "Resource": "arn:aws:kms:*:*:key/wallix-key-id"  // Replace with specific KMS key ARN
      },
      {
        "Sid": "CloudWatchLogs",
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:log-group:/wallix/*"
      },
      {
        "Sid": "S3RecordingArchive",
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::wallix-recordings-bucket",
          "arn:aws:s3:::wallix-recordings-bucket/*"
        ]
      }
    ]
  }

+==============================================================================+
```

---

## Azure Deployment

### Azure Architecture

```
+==============================================================================+
|                   AZURE DEPLOYMENT ARCHITECTURE                              |
+==============================================================================+

                          +------------------+
                          |    INTERNET      |
                          +--------+---------+
                                   |
  +--------------------------------+----------------------------------+
  |                        Azure Region                               |
  |                        (East US)                                  |
  |                                                                   |
  |  Resource Group: rg-wallix-prod                                   |
  |  +-------------------------------------------------------------+  |
  |  |                                                             |  |
  |  |  Virtual Network: vnet-wallix (10.0.0.0/16)                 |  |
  |  |  +-------------------------------------------------------+  |  |
  |  |  |                                                       |  |  |
  |  |  |  +-------------------+   +-------------------+        |  |  |
  |  |  |  | Subnet: frontend  |   | Subnet: backend   |        |  |  |
  |  |  |  | 10.0.1.0/24       |   | 10.0.10.0/24      |        |  |  |
  |  |  |  |                   |   |                   |        |  |  |
  |  |  |  | +---------------+ |   | +---------------+ |        |  |  |
  |  |  |  | | Azure LB /    | |   | | WALLIX VM 1   | |        |  |  |
  |  |  |  | | App Gateway   | |   | | (Primary)     | |        |  |  |
  |  |  |  | +-------+-------+ |   | | Standard_D4s  | |        |  |  |
  |  |  |  |         |         |   | +-------+-------+ |        |  |  |
  |  |  |  +---------+---------+   |         |         |        |  |  |
  |  |  |            |             | +-------+-------+ |        |  |  |
  |  |  |            +-------------+-+ WALLIX VM 2   | |        |  |  |
  |  |  |                          | | (Standby)     | |        |  |  |
  |  |  |                          | | Standard_D4s  | |        |  |  |
  |  |  |                          | +---------------+ |        |  |  |
  |  |  |                          +-------------------+        |  |  |
  |  |  |                                                       |  |  |
  |  |  |  +-------------------+   +-------------------+        |  |  |
  |  |  |  | Subnet: data      |   | Subnet: services  |        |  |  |
  |  |  |  | 10.0.20.0/24      |   | 10.0.30.0/24      |        |  |  |
  |  |  |  |                   |   |                   |        |  |  |
  |  |  |  | +---------------+ |   | +---------------+ |        |  |  |
  |  |  |  | | Azure DB for  | |   | | Azure Files   | |        |  |  |
  |  |  |  | | PostgreSQL    | |   | | (Recordings)  | |        |  |  |
  |  |  |  | +---------------+ |   | +---------------+ |        |  |  |
  |  |  |  |                   |   |                   |        |  |  |
  |  |  |  | +---------------+ |   | +---------------+ |        |  |  |
  |  |  |  | | Key Vault     | |   | | Log Analytics | |        |  |  |
  |  |  |  | +---------------+ |   | +---------------+ |        |  |  |
  |  |  |  +-------------------+   +-------------------+        |  |  |
  |  |  |                                                       |  |  |
  |  |  +-------------------------------------------------------+  |  |
  |  |                                                             |  |
  |  +-------------------------------------------------------------+  |
  |                                                                   |
  +-------------------------------------------------------------------+

+==============================================================================+
```

### Azure VM Sizing

```
+==============================================================================+
|                   AZURE VM RECOMMENDATIONS                                   |
+==============================================================================+

  +------------+------------------+-------+--------+-------------------------+
  | Deployment | VM Size          | vCPU  | Memory | Use Case                |
  +------------+------------------+-------+--------+-------------------------+
  | POC/Lab    | Standard_D2s_v5  | 2     | 8 GB   | Testing, evaluation     |
  | Small      | Standard_D4s_v5  | 4     | 16 GB  | < 100 sessions          |
  | Medium     | Standard_D8s_v5  | 8     | 32 GB  | 100-500 sessions        |
  | Large      | Standard_D16s_v5 | 16    | 64 GB  | 500-1000 sessions       |
  | Enterprise | Standard_D32s_v5 | 32    | 128 GB | 1000+ sessions          |
  +------------+------------------+-------+--------+-------------------------+

  STORAGE RECOMMENDATIONS
  =======================

  +------------------+------------------+-----------------------------------+
  | Disk             | Type             | Size                              |
  +------------------+------------------+-----------------------------------+
  | OS Disk          | Premium SSD P10  | 128 GB                            |
  | Data Disk        | Premium SSD P20  | 512 GB (database)                 |
  | Recordings       | Azure Files      | Premium, 1 TB+ (shared)           |
  +------------------+------------------+-----------------------------------+

+==============================================================================+
```

### Azure Deployment (ARM Template)

```
+==============================================================================+
|                   AZURE ARM TEMPLATE (SIMPLIFIED)                            |
+==============================================================================+

  {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "vmSize": {
        "type": "string",
        "defaultValue": "Standard_D4s_v5"
      },
      "adminUsername": {
        "type": "string"
      },
      "adminPassword": {
        "type": "securestring"
      }
    },
    "resources": [
      {
        "type": "Microsoft.Network/virtualNetworks",
        "apiVersion": "2021-05-01",
        "name": "vnet-wallix",
        "location": "[resourceGroup().location]",
        "properties": {
          "addressSpace": {
            "addressPrefixes": ["10.0.0.0/16"]
          },
          "subnets": [
            {
              "name": "backend",
              "properties": {
                "addressPrefix": "10.0.10.0/24"
              }
            }
          ]
        }
      },
      {
        "type": "Microsoft.Compute/virtualMachines",
        "apiVersion": "2021-07-01",
        "name": "vm-wallix-primary",
        "location": "[resourceGroup().location]",
        "properties": {
          "hardwareProfile": {
            "vmSize": "[parameters('vmSize')]"
          },
          "storageProfile": {
            "imageReference": {
              "publisher": "wallix",
              "offer": "wallix-bastion",
              "sku": "enterprise",
              "version": "latest"
            },
            "osDisk": {
              "createOption": "FromImage",
              "managedDisk": {
                "storageAccountType": "Premium_LRS"
              }
            }
          },
          "osProfile": {
            "computerName": "wallix-primary",
            "adminUsername": "[parameters('adminUsername')]",
            "adminPassword": "[parameters('adminPassword')]"
          },
          "networkProfile": {
            "networkInterfaces": [
              {
                "id": "[resourceId('Microsoft.Network/networkInterfaces',
                        'nic-wallix-primary')]"
              }
            ]
          }
        }
      },
      {
        "type": "Microsoft.DBforPostgreSQL/flexibleServers",
        "apiVersion": "2021-06-01",
        "name": "psql-wallix",
        "location": "[resourceGroup().location]",
        "sku": {
          "name": "Standard_D2s_v3",
          "tier": "GeneralPurpose"
        },
        "properties": {
          "version": "14",
          "administratorLogin": "wallix",
          "administratorLoginPassword": "[parameters('adminPassword')]",
          "storage": {
            "storageSizeGB": 256
          },
          "highAvailability": {
            "mode": "ZoneRedundant"
          }
        }
      }
    ]
  }

+==============================================================================+
```

---

## Google Cloud Platform

### GCP Architecture

```
+==============================================================================+
|                   GCP DEPLOYMENT ARCHITECTURE                                |
+==============================================================================+

                          +------------------+
                          |    INTERNET      |
                          +--------+---------+
                                   |
  +--------------------------------+----------------------------------+
  |                      GCP Project                                  |
  |                                                                   |
  |  VPC Network: wallix-vpc                                          |
  |  +-------------------------------------------------------------+  |
  |  |                                                             |  |
  |  |  Region: us-central1                                        |  |
  |  |  +-------------------------------------------------------+  |  |
  |  |  |                                                       |  |  |
  |  |  |  +------------------+    +------------------+         |  |  |
  |  |  |  | Subnet: frontend |    | Subnet: backend  |         |  |  |
  |  |  |  | 10.0.1.0/24      |    | 10.0.10.0/24     |         |  |  |
  |  |  |  |                  |    |                  |         |  |  |
  |  |  |  | +------------+   |    | +------------+   |         |  |  |
  |  |  |  | | Cloud LB   |   |    | | WALLIX GCE |   |         |  |  |
  |  |  |  | | (HTTPS)    |   |    | | Instance 1 |   |         |  |  |
  |  |  |  | +------+-----+   |    | | n2-std-4   |   |         |  |  |
  |  |  |  |        |         |    | +------+-----+   |         |  |  |
  |  |  |  +--------+---------+    |        |         |         |  |  |
  |  |  |           |              | +------+-----+   |         |  |  |
  |  |  |           +--------------+-+ WALLIX GCE |   |         |  |  |
  |  |  |                          | | Instance 2 |   |         |  |  |
  |  |  |                          | | n2-std-4   |   |         |  |  |
  |  |  |                          | +------------+   |         |  |  |
  |  |  |                          +------------------+         |  |  |
  |  |  |                                                       |  |  |
  |  |  |  +------------------+    +------------------+         |  |  |
  |  |  |  | Cloud SQL        |    | Filestore        |         |  |  |
  |  |  |  | (PostgreSQL)     |    | (Recordings)     |         |  |  |
  |  |  |  | HA Configuration |    | Premium Tier     |         |  |  |
  |  |  |  +------------------+    +------------------+         |  |  |
  |  |  |                                                       |  |  |
  |  |  |  +------------------+    +------------------+         |  |  |
  |  |  |  | Secret Manager   |    | Cloud Logging    |         |  |  |
  |  |  |  +------------------+    +------------------+         |  |  |
  |  |  |                                                       |  |  |
  |  |  +-------------------------------------------------------+  |  |
  |  |                                                             |  |
  |  +-------------------------------------------------------------+  |
  |                                                                   |
  +-------------------------------------------------------------------+

+==============================================================================+
```

### GCP Instance Sizing

```
+==============================================================================+
|                   GCP COMPUTE ENGINE RECOMMENDATIONS                         |
+==============================================================================+

  +------------+------------------+-------+--------+-------------------------+
  | Deployment | Machine Type     | vCPU  | Memory | Use Case                |
  +------------+------------------+-------+--------+-------------------------+
  | POC/Lab    | e2-standard-2    | 2     | 8 GB   | Testing, evaluation     |
  | Small      | n2-standard-4    | 4     | 16 GB  | < 100 sessions          |
  | Medium     | n2-standard-8    | 8     | 32 GB  | 100-500 sessions        |
  | Large      | n2-standard-16   | 16    | 64 GB  | 500-1000 sessions       |
  | Enterprise | n2-standard-32   | 32    | 128 GB | 1000+ sessions          |
  +------------+------------------+-------+--------+-------------------------+

  GCP DEPLOYMENT COMMANDS
  =======================

  # Create VPC
  gcloud compute networks create wallix-vpc --subnet-mode=custom

  # Create subnet
  gcloud compute networks subnets create wallix-backend \
    --network=wallix-vpc \
    --region=us-central1 \
    --range=10.0.10.0/24

  # Create firewall rules
  gcloud compute firewall-rules create wallix-allow-https \
    --network=wallix-vpc \
    --allow=tcp:443 \
    --source-ranges=0.0.0.0/0

  gcloud compute firewall-rules create wallix-allow-ssh-rdp \
    --network=wallix-vpc \
    --allow=tcp:22,tcp:3389 \
    --source-ranges=<user-ip-ranges>

  # Create instance
  gcloud compute instances create wallix-primary \
    --zone=us-central1-a \
    --machine-type=n2-standard-4 \
    --image-project=wallix-public \
    --image-family=wallix-bastion \
    --boot-disk-size=100GB \
    --boot-disk-type=pd-ssd \
    --network=wallix-vpc \
    --subnet=wallix-backend

  # Create Cloud SQL instance
  gcloud sql instances create wallix-db \
    --database-version=POSTGRES_14 \
    --tier=db-custom-2-8192 \
    --region=us-central1 \
    --availability-type=REGIONAL \
    --storage-size=200GB \
    --storage-type=SSD

+==============================================================================+
```

### GCP Terraform Configuration

```hcl
# GCP WALLIX Bastion Terraform Configuration
# Provider Configuration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

# VPC Network
resource "google_compute_network" "wallix_vpc" {
  name                    = "wallix-vpc"
  auto_create_subnetworks = false
}

# Backend Subnet
resource "google_compute_subnetwork" "wallix_backend" {
  name          = "wallix-backend"
  ip_cidr_range = "10.0.10.0/24"
  region        = var.region
  network       = google_compute_network.wallix_vpc.id
}

# Firewall Rules
resource "google_compute_firewall" "wallix_allow_https" {
  name    = "wallix-allow-https"
  network = google_compute_network.wallix_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["wallix"]
}

resource "google_compute_firewall" "wallix_allow_ssh_rdp" {
  name    = "wallix-allow-ssh-rdp"
  network = google_compute_network.wallix_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = var.allowed_ip_ranges
  target_tags   = ["wallix"]
}

variable "allowed_ip_ranges" {
  description = "IP ranges allowed for SSH/RDP"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

# Service Account
resource "google_service_account" "wallix_sa" {
  account_id   = "wallix-bastion"
  display_name = "WALLIX Bastion Service Account"
}

resource "google_project_iam_member" "wallix_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.wallix_sa.email}"
}

resource "google_project_iam_member" "wallix_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.wallix_sa.email}"
}

# WALLIX Compute Instance
resource "google_compute_instance" "wallix_primary" {
  name         = "wallix-primary"
  machine_type = "n2-standard-4"
  zone         = var.zone

  tags = ["wallix"]

  boot_disk {
    initialize_params {
      image = "projects/wallix-public/global/images/family/wallix-bastion"
      size  = 100
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.wallix_vpc.id
    subnetwork = google_compute_subnetwork.wallix_backend.id

    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.wallix_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

# Cloud SQL PostgreSQL
resource "google_sql_database_instance" "wallix_db" {
  name             = "wallix-db"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier              = "db-custom-2-8192"
    availability_type = "REGIONAL"
    disk_size         = 200
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.wallix_vpc.id
    }
  }

  deletion_protection = true
}

# Filestore for Recordings
resource "google_filestore_instance" "wallix_recordings" {
  name     = "wallix-recordings"
  location = var.zone
  tier     = "PREMIUM"

  file_shares {
    name        = "recordings"
    capacity_gb = 2048
  }

  networks {
    network = google_compute_network.wallix_vpc.name
    modes   = ["MODE_IPV4"]
  }
}

# Outputs
output "wallix_instance_ip" {
  value = google_compute_instance.wallix_primary.network_interface[0].access_config[0].nat_ip
}

output "wallix_db_connection" {
  value = google_sql_database_instance.wallix_db.private_ip_address
}

output "filestore_ip" {
  value = google_filestore_instance.wallix_recordings.networks[0].ip_addresses[0]
}
```

### GCP IAM Permissions for WALLIX

```
+==============================================================================+
|                   GCP IAM CONFIGURATION                                      |
+==============================================================================+

  REQUIRED ROLES FOR WALLIX SERVICE ACCOUNT
  =========================================

  +----------------------------------+----------------------------------------+
  | Role                             | Purpose                                |
  +----------------------------------+----------------------------------------+
  | roles/logging.logWriter          | Write application logs                 |
  | roles/monitoring.metricWriter    | Export performance metrics             |
  | roles/secretmanager.secretAccessor| Access secrets (if used)              |
  | roles/cloudsql.client            | Connect to Cloud SQL                   |
  +----------------------------------+----------------------------------------+

  REQUIRED ROLES FOR DEPLOYMENT
  =============================

  +----------------------------------+----------------------------------------+
  | Role                             | Purpose                                |
  +----------------------------------+----------------------------------------+
  | roles/compute.instanceAdmin.v1   | Create/manage VM instances             |
  | roles/compute.networkAdmin       | Create/manage VPC networks             |
  | roles/cloudsql.admin             | Create/manage Cloud SQL                |
  | roles/file.editor                | Create/manage Filestore                |
  | roles/iam.serviceAccountAdmin    | Create service accounts                |
  +----------------------------------+----------------------------------------+

+==============================================================================+
```

---

## Hybrid Cloud Architecture

### Multi-Cloud / Hybrid Design

```
+==============================================================================+
|                   HYBRID CLOUD ARCHITECTURE                                  |
+==============================================================================+

  +------------------------------------------------------------------------+
  |                                                                        |
  |                         ENTERPRISE NETWORK                             |
  |                                                                        |
  |   ON-PREMISES DATA CENTER                                              |
  |   +--------------------------------------------------------------+    |
  |   |                                                              |    |
  |   |   +------------------+         +------------------+          |    |
  |   |   | WALLIX Bastion   |         | On-Prem Targets  |          |    |
  |   |   | (Primary)        +-------->| Servers, DBs,    |          |    |
  |   |   | Central Mgmt     |         | Network Devices  |          |    |
  |   |   +--------+---------+         +------------------+          |    |
  |   |            |                                                 |    |
  |   +------------|---------------------------------------------+   |    |
  |                |                                                 |    |
  |                | VPN / Direct Connect / ExpressRoute             |    |
  |                |                                                 |    |
  |   +------------+------------------------------------------------+|    |
  |   |            |                                                ||    |
  |   |   +--------+--------+          +------------------+         ||    |
  |   |   |                 |          |                  |         ||    |
  |   v   v                 v          v                  v         ||    |
  |                                                                  |    |
  | +----------------+   +----------------+   +----------------+     |    |
  | |     AWS        |   |     AZURE      |   |     GCP        |     |    |
  | |                |   |                |   |                |     |    |
  | | +-----------+  |   | +-----------+  |   | +-----------+  |     |    |
  | | | WALLIX    |  |   | | WALLIX    |  |   | | WALLIX    |  |     |    |
  | | | Satellite |  |   | | Satellite |  |   | | Satellite |  |     |    |
  | | +-----+-----+  |   | +-----+-----+  |   | +-----+-----+  |     |    |
  | |       |        |   |       |        |   |       |        |     |    |
  | | +-----+-----+  |   | +-----+-----+  |   | +-----+-----+  |     |    |
  | | | EC2       |  |   | | Azure VMs |  |   | | GCE       |  |     |    |
  | | | RDS       |  |   | | Azure SQL |  |   | | Cloud SQL |  |     |    |
  | | | EKS       |  |   | | AKS       |  |   | | GKE       |  |     |    |
  | | +-----------+  |   | +-----------+  |   | +-----------+  |     |    |
  | |                |   |                |   |                |     |    |
  | +----------------+   +----------------+   +----------------+     |    |
  |                                                                  |    |
  +------------------------------------------------------------------+    |
  |                                                                        |
  +------------------------------------------------------------------------+

  HYBRID ARCHITECTURE BENEFITS
  ============================

  * Centralized policy management from on-premises
  * Local session proxying for cloud workloads (reduced latency)
  * Recordings can be stored locally in each cloud
  * Audit logs aggregated centrally
  * Single pane of glass for all environments

+==============================================================================+
```

---

## Cloud Security Considerations

### Cloud-Specific Security

```
+==============================================================================+
|                   CLOUD SECURITY BEST PRACTICES                              |
+==============================================================================+

  IDENTITY & ACCESS
  =================

  +------------------------------------------------------------------------+
  | Practice                        | Implementation                       |
  +---------------------------------+--------------------------------------+
  | Use cloud IAM roles             | Assign minimal permissions to        |
  |                                 | WALLIX service accounts              |
  +---------------------------------+--------------------------------------+
  | Integrate with cloud IdP        | Azure AD, AWS IAM Identity Center,   |
  |                                 | Google Cloud Identity                |
  +---------------------------------+--------------------------------------+
  | Enable MFA everywhere           | Cloud console + WALLIX access        |
  +---------------------------------+--------------------------------------+
  | Rotate credentials              | Use cloud secrets managers           |
  +---------------------------------+--------------------------------------+

  NETWORK SECURITY
  ================

  +------------------------------------------------------------------------+
  | Practice                        | Implementation                       |
  +---------------------------------+--------------------------------------+
  | Private subnets for WALLIX      | No direct internet access to Bastion |
  +---------------------------------+--------------------------------------+
  | Use load balancers              | ALB/NLB, Azure LB, GCP LB for HTTPS  |
  +---------------------------------+--------------------------------------+
  | VPC peering for targets         | Connect to target VPCs securely      |
  +---------------------------------+--------------------------------------+
  | Network ACLs + Security Groups  | Defense in depth                     |
  +---------------------------------+--------------------------------------+
  | Private Link / Endpoints        | Access cloud services privately      |
  +---------------------------------+--------------------------------------+

  DATA PROTECTION
  ===============

  +------------------------------------------------------------------------+
  | Practice                        | Implementation                       |
  +---------------------------------+--------------------------------------+
  | Encrypt data at rest            | EBS/Disk encryption, RDS encryption  |
  +---------------------------------+--------------------------------------+
  | Encrypt data in transit         | TLS 1.2+ everywhere                  |
  +---------------------------------+--------------------------------------+
  | Use cloud KMS                   | AWS KMS, Azure Key Vault, GCP KMS    |
  +---------------------------------+--------------------------------------+
  | Secure recording storage        | Encrypted EFS/Azure Files/Filestore  |
  +---------------------------------+--------------------------------------+

  MONITORING & COMPLIANCE
  =======================

  +------------------------------------------------------------------------+
  | Practice                        | Implementation                       |
  +---------------------------------+--------------------------------------+
  | Enable cloud audit logging      | CloudTrail, Azure Monitor, GCP Audit |
  +---------------------------------+--------------------------------------+
  | Forward WALLIX logs             | CloudWatch, Log Analytics, Stackdriver|
  +---------------------------------+--------------------------------------+
  | Set up alerts                   | Unusual access patterns, failures    |
  +---------------------------------+--------------------------------------+
  | Regular compliance scans        | AWS Config, Azure Policy, GCP SCC    |
  +---------------------------------+--------------------------------------+

+==============================================================================+
```

---

## Next Steps

Continue to [25 - Container Deployment](../25-container-deployment/README.md) for Docker and Kubernetes configurations.
