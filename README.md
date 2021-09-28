# Static Site Boilerplate

## Introduction
This is a static site boilerplate, based off:
https://github.com/h5bp/html5-boilerplate/tree/v8.0.0

## Features
* Support for plain old static/html/css pages
* Vite2 front-end build tool to provide a dev server and lightning fast builds
* Multi-environment support
* Both multiple entry-points (Multi-page app) and single page app writing
* Support for Progressive Web App features
* Easy infra setup and deployment to a low-cost S3 + Cloudflare setup using Terraform.
* < 1 minute deploys
* < 5 minute to provision a new environment

## Dependencies
* Terraform >= 1.2
* Ruby >= 2.6
* Node >= 12

## Credentials
To support automated provisioning and deploying to environments you will need to provide the following credentials inside bin/.env

The AWS Access Key should have S3 access, and the Cloudflare API Token should have access to Workers Scripts:Edit, Workers Routes:Edit, Page Rules:Edit, DNS:Edit

```
CLOUDFLARE_EMAIL=''
CLOUDFLARE_API_TOKEN=''
CLOUDFLARE_ACCOUNT_ID=''
AWS_ACCESS_KEY_ID=''
AWS_SECRET_ACCESS_KEY=''
AWS_REGION=''
```

You will also need to provide the cloudflare zone ID inside your ROOT/environments/[environment.json]. file, per environment.

## Installation
To install the dependencies run the following from the root directory:

```
  npm install
```

## Dev Mode
To run development mode run the following from the root directory:

```
  npm run dev
```

## Configuration
To initiate a new project and configure it for deployment, check out the repository and then:
  - Declare your environments (by copying and renaming the template file at `environments/production.json.sample` and updating its contents)
  - Declare any environment specific variables exposed to the build process in the root dir .env.[environmentname]


## Deployment
This project assumes an opinionated deployment configuration. 
Other configurations are easily possible, but are not supported by the built-in `provision` and `deploy` commands.

### Infrastructure Setup
* For each environment, create a named environment file inside ROOT/environments/[environment.json].
* Ensure the environment file contains the  the fully qualified domain of your site, the name of the subdomain CNAME to provision in Cloudflare, and the cloudflare zone id.
* Run `bin/provision [environment]`
* The output of this command is the website endpoint you will use in your Cloudflare configuration.
* In Cloudflare, create a DNS record to point your domain to this website endpoint.
* Provisioned environments can be destroyed using `bin/destroy`
* See `bin/provision -h` for more details


### Deployment
To deploy, simply run

```
bin/deploy [ENV_NAME]
```
