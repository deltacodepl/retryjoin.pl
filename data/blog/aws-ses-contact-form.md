---
title: HTML Contact form with AWS Services
date: '2022-07-10'
tags: ['AWS']
draft: false
summary:
images: []
---

## HTML Contact form with AWS Services

I would like to present a simple demo, how to use AWS SES and lambda services, to create serverless contact form on a static webpage.

![diagram/diagrams_image.png](https://github.com/deltacodepl/aws-contact-form/blob/main/diagram/diagrams_image.png?raw=true)

I have used this setup successfully on a couple e-commerce pages.

### Project's Structure

The core of serverless application is serverless.yaml

to create sls project from scratch run:

```bash
sls create --template aws-python3
sls plugin install --name serverless-dotenv-plugin
sls plugin install --name serverless-python-requirements
```
