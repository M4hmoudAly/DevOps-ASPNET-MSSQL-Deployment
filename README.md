# DevOps-ASPNET-MSSQL-Deployment
DevOps ASPNET-MSSQL Deployment, dockerized with Kubernetes, on AWS using Terraform.

This documentation contains the necessary configurations and setup to deploy a web application, dockerized with Kubernetes, on AWS using Terraform.

**Table of Contents**
 - Introduction
 - Prerequisites
 - Getting Started
 - Terraform Configuration
 - Dockerized Web App
 - Kubernetes Deployment

## Introduction

This project provides a complete setup to deploy a web application using Kubernetes on AWS. It utilizes Terraform for infrastructure provisioning, Docker for containerizing the web app, and Kubernetes for managing container deployments.

## Project Workflow
- Web application and SQL Server provisioned and running over Kubernetes.
-  Domain name configured and accessible with a valid SSL certificate.
-  Load balancer set up and correctly distributed traffic across instances of the web
application.
-  SQL Server instances are properly configured and secured.
-  Security measures were implemented, including network security groups and
access controls.

## Prerequisites
Before you proceed, ensure that you have the following prerequisites:

- AWS Account: You need an AWS account with appropriate IAM permissions to create resources like Route 53, ACM certificates, EC2 instances, and EKS clusters.
- Terraform: Install Terraform on your local machine. You can download the Terraform binary from the [official website](https://www.terraform.io/downloads.html).
- Docker: Install Docker on your local machine to build and run container images. Refer to the [Docker documentation](https://docs.docker.com/get-docker/) for installation instructions.
- kubectl: Install kubectl on your local machine to manage Kubernetes clusters. Follow the [kubectl installation guide](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for detailed instructions.

## Architecture Overview
The architecture consists of the following components:
- AWS Infrastructure: Provisioned using Terraform, this includes Route 53 for domain management, ACM certificate for HTTPS, and an EC2 instance with an EKS cluster to run Kubernetes.
- Dockerized Web App: The web application code is containerized using Docker, allowing easy deployment and isolation of dependencies.
- Kubernetes Deployment: Kubernetes orchestrates the deployment of the Dockerized web app, managing scaling, rolling updates, and load balancing.

## Getting Started
Follow these steps to deploy the web application dockerized with Kubernetes on AWS:

Step 1: Terraform Configuration
Navigate to the "app" folder.
```sh
$ cd aspnet-mssql/app
```
Initialize Terraform to download required plugins if not downloaded.
```sh
$ terraform init
```

Apply the Terraform configuration to create AWS resources.
```sh
$ terraform apply
```

Step 2: Dockerized Web App
Navigate to the directory of the web app.
```sh
$ cd aspnet-mssql/app/aspnetapp
```
Build the Docker image for the web app.
```sh
$ docker build -t
```

### Deploy with docker compose
- The compose file defines an application with two services web and db. The image for the web service is built with the Dockerfile inside the app directory (build parameter).
- When deploying the application, docker compose maps the container port 80 to port 80 of the host as specified in the file. Make sure port 80 on the host is not being used by another container, otherwise the port should be changed.

Navigate to the directory of the docker compose.
```sh
$ docker compose up -d
```
Push the Docker image to the ECR repository.
```sh
$ docker push <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/my-web-app:latest
```
