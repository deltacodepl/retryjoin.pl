---
title: AWS EKS for django application
date: '2022-12-20'
tags: ['AWS', 'Python', 'Kubernetes']
draft: true
summary:
images: []
---

Currently I want to build some small landing page on django with admin backend and put it in the cloud.
Lets build infrastructure for our deployment using AWS and their managed kubernetes EKS platform.

<Image alt="eks" src="/static/images/django-eks.drawio.png" width={500} height={350} />

First we try to build generic cluster for django application using great module **terraform-aws-modules/eks/aws**. Our terraform project will be creating:

1. VPC networking with at least 2 az

- Private and public subnets for each zone
- 1 NAT Gateway
- Internet Gateway
- Route tables

2. Security Groups
3. Iam User and Role to configure access to the cluster by aws-auth config map
4. AWS LB Controller
5. EKS Cluster with managed node groups

We will start with the VPC, by using module **terraform-aws-modules/vpc/aws**, we can do it within a couple minutes, by just setting up some variables:

```hcl
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

Our basic networking is ready because eks module is taking care of necessary components for us. So it's time for IAM:

First lets create policy for admin user with access rights to the cluster:

```json
source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
...

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

Next we are creating an assumable role that will use this policy:

```json
source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
...

role_name         = "eks-admin"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
```

and iam group for our admin users, with policy that allows us to assume the role:

```json
source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
...

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

Ok, lets setup eks module, we put the cluster into our private subnets, because we don't have a direct vpn connection to the vpc, we will also setup public access by using endpoint. For testing purposes we will use also a SPOT instances with our cluster, in real use case we could use it for some interruptible computations for example.
Setting up **aws_auth_roles** with our assumable role let us get control over the cluster.

```hcl
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

When we run `terraform apply`, and everything has gone rigth, we are ready to get access to the cluster and install some test manifest.
To run as user we have created ealier, we need to configure local profile for ekadmin user `aws configure --profile ekadmin` and
add role arn to **~/.aws/config** file:

```bash
[profile ekadmin]
role_arn = arn:aws:iam::${ACCOUNT_ID}:role/eks-admin
source_profile = ekadmin
region = eu-central-1
output = json
```

By running
`aws sts get-caller-identity --profile ekadmin` we can check if we have proper access to the AWS

To connect to the cluster we update our context first, and then deploy simple nginx service:

```bash
aws eks update-kubeconfig --name django-helm-eks-terraform --profile ekadmin
kubectl apply -f  ../k8s/nginx.yaml
```

<Image alt="EKS" src="/static/images/eks.png" width={800} height={235} />

By taking DNS of loadbalancer created by kubernetes addon we have installed, we can get access to our newly deployed service:
