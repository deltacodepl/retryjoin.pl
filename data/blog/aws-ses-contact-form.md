---
title: HTML Contact form with AWS Services
date: '2022-07-10'
tags: ['AWS', 'Lambda', 'Python']
draft: false
summary:
images: []
---

## HTML Contact form with AWS SES and Lambda

I would like to present a very simple demo, how to use AWS SES and lambda services, to create serverless contact form on a static webpage.

![diagram/diagrams_image.png](https://github.com/deltacodepl/aws-contact-form/blob/main/diagram/diagrams_image.png?raw=true)

Github repo: https://github.com/deltacodepl/aws-contact-form

I have used this setup successfully on a couple e-commerce pages, so it's quite handy :).

Project consist of two parts, the static content within s3 website bucket and serverless application.

The point where everything starts it's a simple static **HTML form**, where we can gather some data like
**sender name, email, and the message**, from our client, using some vanilla javascript:

```javascript
const callAPI = (event) => {
        event.preventDefault();
        const name = document.getElementById("name").value
        const email = document.getElementById("email").value
        const message = document.getElementById("message").value
        // const to display message to the user after email is send
        const formMessage = document.querySelector('.form-message');

        const data = {
            senderName: name,
            email: email,
            message: message
        }
        // actually call the AWS API
        fetch('https://2t9avuoyw0.execute-api.eu-central-1.amazonaws.com/contact',
            {
                method: 'POST',
                mode: 'cors',
                headers: {
                    'Content-Type': 'application/json'
                },
                // serialize form data
                body: JSON.stringify(data)
            }
        )
        ...
```

we put every static content into **S3** bucket.

### Serverless project's structure

To create sls project from scratch run:

```bash
sls create --template aws-python3
sls plugin install --name serverless-dotenv-plugin
sls plugin install --name serverless-python-requirements
```

The core of serverless application is serverless.yml and handler.py files.
We will change handler file name for better suited for our needs **send_email.py**

Main part of serverless.yml allows us to specify runtime, region, **API gateway** and **IAM role** :

```yaml
provider:
  name: aws
  runtime: python3.8
  environment:
  stage: ${env:STAGE, 'dev'}
  region: ${env:REGION, 'eu-central-1'}
  httpApi:
    cors:
      allowedOrigins:
        - ${env:CORS1}
        - ${env:CORS2}
  iam:
    role:
      statements:
        - Effect: Allow
          Action:
            - ses:SendEmail
            - ses:SendRawEmail
            - ses:VerifyEmailIdentity
            - ses:VerifyDomainIdentity
            - ses:DeleteIdentity
          Resource: '*'
```

and of course our **lambda function** :

```yaml
functions:
  #    Define function environment variables here
  #    environment:
  #      variable2: value2
  contact:
    handler: send_email.sendEmail
    events:
      - httpApi:
          path: /contact
          method: post
```

Lambda function works basing on http event (wich comes from http api call):

```python
# lambda handler event, context
def sendEmail(event, context):
...
```

all the data comes from our HTML form:

we can easily get message body from the event:

```python
body = json.loads(event['body'])
        data = {
            "senderName": body.get('senderName'),
            "email": body.get('email'),
            "message": body.get('message')
        }
```

and send our email using boto3 library

https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ses.html#SES.Client.send_email

> email verification is needed to work with SES service (it works only with requested region)

to load env variables from .env file, we can use manual export

```bash
export $(grep -v '^#' .env | xargs)
```

after running `sls deploy` command, we get endpoint address, wich we can put in our html/javascript form's code, and upload website's static files to s3 bucket.

```bash
✔ Service deployed to stack aws-ses-contact-form-dev (64s)

endpoint: POST - https://2t9avuoyw0.execute-api.eu-central-1.amazonaws.com/contact
functions:
  contact: aws-ses-contact-form-dev-contact (11 MB)
```

after visiting `http://<bucket_name>.s3-website-us-east-1.amazonaws.com/`
we can test our small setup

<Image alt="contact-form" src="/static/images/basic_tailwind_starter.png" width={400} height={530} />
