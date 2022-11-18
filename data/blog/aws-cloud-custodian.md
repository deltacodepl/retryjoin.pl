---
title: Cloud Custodian - Cloud Governance Tool
date: '2022-10-01'
tags: ['AWS', 'Lambda', 'Python', 'Governance']
draft: false
summary:
images: []
---

Currently I work with some kind an utility - cloud native policy tool, to keep a whole AWS infrastracture in tight, good shape, to easy the inventarisation, security and even finops.

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
