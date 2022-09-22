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
After modifying your script, compress and upload your source code.   
For long-term maintenance, I recommend using CircleCI for deployment.