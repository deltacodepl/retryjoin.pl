---
title: AWS EKS for django application
date: '2022-12-20'
tags: ['AWS', 'Python', 'Kubernetes']
draft: true
summary:
images: []
---

Currently I want to build some small landing page, I will be using django based project template with admin backend for this project.
Lets build infrastructure for our deployment using AWS cloud and their EKS platform.

First we try to build generic cluster for django application using great module **terraform-aws-modules/eks/aws**. Our terraform project will be creating:

1. VPC with at least 2 az

- Private and public subnets for each zone
- 1 NAT Gateway
- Internet Gateway
- Route tables

2. Security Groups
3. Iam User and Role to configure access to the cluster by aws-auth config map
4. AWS LB Controller
5. EKS Cluster

We will start with the VPC, by using module **terraform-aws-modules/vpc/aws**, we can do it within a couple minutes, by just setting up some variables:

```yaml
  name                 = "${var.app_name}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = local.azs
  private_subnets      = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 10)]
  public_subnets       = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  one_nat_gateway_per_az = false
  enable_dns_support   = true
  enable_dns_hostnames = true
```

Our basic networking is ready. Time for IAM:

First lets create policy for admin user with access rights to the cluster:

```json
policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
```

Next we are creating a assumable role that will use this policy:

```json
role_name         = "eks-admin"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
```

and iam group for our admin users, with policy that allows us to do this:

```json
policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.eks_admins_iam_role.iam_role_arn
      },
    ]
  })
```

Ok, lets setup eks module,

```json
subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  eks_managed_node_group_defaults = {
    disk_size = 30
  }

  eks_managed_node_groups = {
    general = {
      desired_size = 1
      min_size     = 1
      max_size     = 2

      labels = {
        role = "general"
      }

      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
    }

    spot = {
      desired_size = 1
      min_size     = 1
      max_size     = 2

      labels = {
        role = "spot"
      }

      taints = [{
        key    = "market"
        value  = "spot"
        effect = "NO_SCHEDULE"
      }]

      instance_types = ["t3.micro"]
      capacity_type  = "SPOT"
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn
      username = module.eks_admins_iam_role.iam_role_name
      groups   = ["system:masters"]
    },
  ]
```

It's the **Cloud Custodian** (https://cloudcustodian.io/) from CapitalOne.
Basically, it's an open-source rule engine, where you can write policy definitions in YAML. This gives us a possibility to manage public cloud resources by writing policies for **cost savings, explore tagging, compliance, security and operations related concerns**, which I find quite useful.

<Image alt="custodian" src="/static/images/custodian.png" width={500} height={350} />

### **Key Features**:

1.  Can be integrated seamlessly with AWS services like AWS Tower, Hub Security. Gives a possibility to check on company's compliance requirements.
2.  Real-Time Guard rails, that take action on the resources to do auto-remediation.
3.  Can filter on certain values of resources and define actions to be taken at certain time intervals or in realtime leveraging CloudTrail events.
4.  Can act on an existing or newly created resources.
5.  Supports auto tagging resource with user name who created it.
6.  Produces the output which can be ingested into a Security Information and Event Management solution (SIEM).

### Simple test run

I have prepared a basic terraform script that spines up a VM with custodian installed within python venv environment, so you can easy test it.
https://github.com/deltacodepl/terraform-aws-custodian.git

Lets say we want to check on every time when someones launches en EC2 instance, if EC2 has owner tag, if not we will tag it automatically with the id of Api caller.

```yaml
policies:
  - name: ec2-auto-tag
    resource: aws.ec2
    description: |
      Find ec2 that has not been tagged with mandatory tag on-creation. 
      Tag ec2 with the user who created it.
    mode:
      type: cloudtrail
      role: default-custodian-role
      events:
        - source: ec2.amazonaws.com
          event: RunInstances
          ids: 'responseElements.instancesSet.items[].instanceId'
      execution-options:
        output_dir: s3://custodian-logs/
      runtime: python3.8
    filters:
      - 'tag:created-by': absent
    actions:
      - type: auto-tag-user
        tag: created-by
        principal_id_tag: principal-id
```

We have used here RunInstances event from CloudTrail with company of JMESPath id

> responseElements.instancesSet.items[].instanceId

filter by absent tag, and principalId from logs as well which let us easly identify owner of the EC2 instance.

You can play with bunch of different examples from theirs docs https://cloudcustodian.io/docs/aws/examples/index.html .
