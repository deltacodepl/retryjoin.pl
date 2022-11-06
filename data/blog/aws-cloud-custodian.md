---
title: Cloud Custodian - Cloud Governance Tool
date: '2022-11-0'
tags: ['AWS', 'Lambda', 'Python', 'Governance']
draft: true
summary:
images: []
---

A Cloud Custodian (https://cloudcustodian.io/) is an open-source from CapitalOne written in python language and comprises many tools and scripts. It is a rule engine where you can write policy definitions in YAML. This enables an organization to manage their public cloud resources by writing policies for **cost savings, explore tagging, compliance, security, operations related concerns, and resource inventory**.

> Open Source, Python, Serverless, Agentless, Policy-as-a-Code, Real-Time Guard Rail, Visibility, Powerful Cloud Security Management Tool

![]()

### **Key Features**:

1.  Enables you to check on your compliance requirements.
2.  Real-Time Guard rails, that take action on the resources to do auto-remediation.
3.  **Best in class to filter on certain values and define actions to be taken at certain time intervals. For example- mark now, notify the user, and delete after 1 hour, and then notify again. Hence, allows using a wide variety of combinations to meet your use cases.**
4.  **Allows you to define if action needs to be taken on an existing or newly created resources.**
5.  Supports auto tagging resource with user name.
6.  Produces the output which can be ingested into a Security Information and Event Management solution (SIEM).

### Simple test run

```yaml
policies:
  - name: find-all-elb
    resource: aws.app-elb
```

output:

```json
[
  {
    "LoadBalancerArn": "arn:aws:elasticloadbalancing:eu-central-1:615263381294:loadbalancer/app/alb1/f7bbf4eae13104fc",
    "DNSName": "alb1-1664155659.eu-central-1.elb.amazonaws.com",
    "CanonicalHostedZoneId": "Z215JYRZR1TBD5",
    "CreatedTime": "2022-10-26T08:07:06.070000+00:00",
    "LoadBalancerName": "alb1",
    "Scheme": "internet-facing",
    "VpcId": "vpc-062e68042f3475bd5",
    "State": {
      "Code": "active"
    },
    "Type": "application",
    "AvailabilityZones": [
      {
        "ZoneName": "eu-central-1a",
        "SubnetId": "subnet-0ded831b97da8f247",
        "LoadBalancerAddresses": []
      },
      {
        "ZoneName": "eu-central-1b",
        "SubnetId": "subnet-0e31d45db6c813bf0",
        "LoadBalancerAddresses": []
      }
    ],
    "SecurityGroups": ["sg-041094637c498e015"],
    "IpAddressType": "ipv4",
    "Tags": [
      {
        "Key": "env",
        "Value": "dev"
      },
      {
        "Key": "service",
        "Value": "contact-form"
      }
    ]
  }
]
```

Examples

### EBS unattached volumes

```yaml

policies:

	- name: ebs-mark-unattached-deletion

	resource: ebs

	comments: |

	Mark any unattached EBS volumes for deletion in 30 days.

	Volumes set to not delete on instance termination do have

	valid use cases as data drives, but 99% of the time they

	appear to be just garbage creation.

	filters:

	- Attachments: []

	- "tag:maid_status": absent

	actions:

	- type: mark-for-op

	op: delete

	days: 30
```

![[Pasted image 20221026180228.png]]

### AWS Tagging Best Practices

![[Pasted image 20221026182244.png]]
