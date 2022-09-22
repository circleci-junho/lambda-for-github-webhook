## Lambda for GitHub webhook
This repo shows the sample script triggering CircleCI API from GitHub webhook payload.

## Configureation
```
# Set up enviroment values from the sample
cp ./terraform/terraform.tfvars.sample ./terraform/terraform.tfvars
```

```
# Create zip file.
cd src
zip -r lambda lambda.zip .
```

```
# Create API Gateway / Lambda from terraform
make apply
```

## Usage
After modifying [the script](https://github.com/circleci-junho/lambda-for-github-webhook/blob/main/src/index.js), compress and upload your source code.   
(For long-term maintenance, I recommend using CircleCI for deployment)

Make sure the webhook sends a payload to lambda endpoint.  
```
Setting > webhooks > Add webhook > Payload URL

# you can configure which events would you like to trigger, please check below details
# https://docs.github.com/en/developers/webhooks-and-events/events/github-event-types
```