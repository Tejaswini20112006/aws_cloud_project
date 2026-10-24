
# Automated Deployment of a Cloud-Based Student Application Using Terraform

A student directory project with a live browser-based demo and optional AWS infrastructure managed using Terraform Infrastructure as Code (IaC).

## Live demo

**StudentHub:** https://web-beige-gamma-65.vercel.app

The live version is hosted as a static site on Vercel. It lets you add, view, refresh, and delete student entries. Records are stored in the browser’s `localStorage`, so each browser has its own data. Records are not shared between users or devices.

The live Vercel app does not call AWS. You do not need AWS credentials or Terraform to use the demo.

## Project goals

This project demonstrates two deployment approaches for a student directory:

1. **Browser-only demo:** A static web app hosted on Vercel. It is intended for trying the interface without provisioning AWS resources.
2. **Optional AWS infrastructure:** Terraform definitions for an S3-hosted website, an API Gateway HTTP API, a Lambda function, and a DynamoDB table.

The AWS configuration is included as a learning example. It is separate from the current Vercel deployment.

## Features

- Student form with name, email, and course fields.
- Browser-based student list with a record count.
- Add and delete records in the Vercel demo.
- Browser `localStorage` persistence between visits in the same browser.
- Input validation for required fields and email format in the browser.
- HTML escaping when student data is displayed.
- Optional Lambda API for create, read, update, and delete operations.
- Terraform configuration for provisioning the optional AWS resources.
- Configurable AWS region, project name, and allowed frontend origin.

## Architecture

### Current Vercel demo

text
User's browser
    |
    v
Vercel static hosting
    |
    v
Browser localStorage


In this version, the browser handles student record operations. There is no shared database or backend API, so data saved in one browser is not available in another browser or device.

### Optional Terraform and AWS deployment

text
Browser
   |
   +--> S3 static website
   |
   +--> API Gateway HTTP API
               |
               v
          AWS Lambda
               |
               v
           DynamoDB


Terraform defines and connects the AWS services. The Lambda function handles API requests and reads or writes student records in DynamoDB.

**The optional AWS deployment can incur charges.** AWS pricing, free-tier eligibility, and usage limits depend on the account, region, and current AWS terms. Do not run `terraform apply` if you need to avoid AWS charges. The Vercel demo works without the AWS deployment.

## Repository structure

text
.
├── lambda/
│   └── app.py
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   └── versions.tf
├── web/
│   ├── index.html
│   ├── vercel.json
│   └── .gitignore
├── .gitignore
└── README.md


### Main files

- `web/index.html` — StudentHub interface and browser-local demo logic.
- `web/vercel.json` — Vercel static-site configuration.
- `lambda/app.py` — Python Lambda handler for the optional student API.
- `terraform/main.tf` — AWS resources, permissions, API routes, and website configuration.
- `terraform/variables.tf` — Terraform input variables.
- `terraform/outputs.tf` — Website URL, API URL, and DynamoDB table name.
- `terraform/versions.tf` — Terraform and provider version constraints.
- `terraform/terraform.tfvars.example` — Example Terraform settings.
- `.gitignore` — Excludes Terraform state, generated files, deployment metadata, and local secrets.

## Run the browser-only demo

### Use the deployed version

Open:

https://web-beige-gamma-65.vercel.app

Add a student using the form. The record appears in the directory and remains in that browser after refresh. Use the delete button to remove a record.

### Run locally

You can open `web/index.html` directly in a modern browser, or serve the `web` directory with a local static web server.

For example, with Python installed:

bash
cd web
python -m http.server 8000


Then open:

text
http://localhost:8000


The browser-only demo saves data under the `studenthub-records` key in `localStorage`. Clearing browser site data may remove those records.

## Deploy the static site to Vercel

The project’s web directory contains the static app and Vercel configuration. To deploy an update, install the Vercel CLI and sign in first. Then run:

bash
cd web
vercel
vercel --prod


This deployment path does not require AWS credentials or Terraform. Check the current Vercel plan and usage limits for your account.

## Optional AWS deployment with Terraform

> **Cost notice:** Applying this Terraform configuration creates real AWS resources and may incur charges. The AWS backend is optional. Skip this section if you want to use only the no-cost browser demo.

### Prerequisites

For the optional AWS deployment, you need:

- Terraform 1.6 or later.
- An AWS account.
- AWS CLI credentials configured for that account.
- Permission to create IAM roles and policies, Lambda functions, API Gateway APIs, DynamoDB tables, and S3 buckets.
- Network access to download Terraform providers.

### Configure Terraform

From the repository root:

bash
cd terraform


Copy the sample variables file:

bash
cp terraform.tfvars.example terraform.tfvars


On Windows PowerShell, use:

powershell
Copy-Item terraform.tfvars.example terraform.tfvars


Edit `terraform.tfvars` before deployment. For example:

hcl
aws_region     = "us-east-1"
project_name   = "student-app"
allowed_origin = "https://your-frontend.example"


Set `allowed_origin` to the exact browser origin that should call the API. The example file uses `"*"`, which permits requests from any origin at the browser CORS layer. CORS is not authentication or authorization.

### Preview and validate the infrastructure

Run:

bash
terraform init
terraform fmt -check
terraform validate
terraform plan


Review the plan carefully. It describes the AWS resources Terraform intends to create or change.

Only if you intend to create AWS resources and accept any associated charges, run:

bash
terraform apply


Terraform will ask for confirmation before applying unless you pass an automatic approval option. The project does not require automatic approval.

### Terraform outputs

After a successful apply, Terraform reports:

- `website_url` — S3 static website endpoint.
- `api_url` — API Gateway HTTP API endpoint.
- `students_table` — DynamoDB table name.

The website endpoint configured here uses S3 static website hosting over HTTP. Do not use it to serve sensitive student information.

### Remove the optional AWS resources

To ask Terraform to remove the resources managed by this configuration:

bash
terraform destroy


Review the destroy plan before confirming. Destroying the DynamoDB table deletes its student records. Back up any data you need first.

## Optional API routes

The Lambda function supports these API routes:

| Method | Route | Purpose |
|---|---|---|
| `GET` | `/students` | List student records |
| `POST` | `/students` | Create a student record |
| `GET` | `/students/{id}` | Retrieve one student by ID |
| `PUT` | `/students/{id}` | Replace a student record |
| `DELETE` | `/students/{id}` | Delete a student record |

For `POST` and `PUT`, the request body must contain non-empty `name`, `email`, and `course` fields. A newly created student receives a generated UUID as its `student_id`.

Example request body:

json
{
  "name": "Aarav Mehta",
  "email": "aarav@example.edu",
  "course": "Computer Science"
}


The Lambda function returns JSON responses. It returns a client error for missing required fields or invalid JSON, a not-found response for unknown routes or missing individual records, and a server error if an unexpected backend error occurs.

The list operation uses a DynamoDB `Scan`. This is acceptable for a small learning project, but can become inefficient as a table grows.

## Data and deployment behavior

- The current Vercel app stores records in the visitor’s browser.
- The optional AWS API stores records in DynamoDB.
- The current Vercel app does not automatically switch to the optional AWS API.
- Deploying the Terraform configuration is a separate action and does not change the current Vercel site.
- Browser-local records and AWS DynamoDB records are separate datasets.

## Security and production limitations

This project is intended for learning and demonstration. It is not a production student information system.

- The sample API has no user authentication or authorization.
- The S3 website policy makes website objects publicly readable.
- The S3 static website endpoint uses HTTP.
- CORS settings do not secure an API or replace authentication.
- Do not enter or store real student personal information in the demo.
- For production use, add authentication, authorization, HTTPS, input and access controls, logging, backups, and appropriate privacy protections.
- Keep AWS credentials and Vercel tokens out of source control.
- Do not commit `.env` files, Terraform state files, Terraform plans, or generated archives.
- Terraform state can contain sensitive infrastructure information. Store it securely, especially when working with a team.

## Troubleshooting

### The Vercel app opens, but I cannot see records from another device

The live version uses browser `localStorage`. Each browser/device has its own records. A shared database-backed app would require deploying and connecting a backend.

### Terraform reports missing AWS credentials

The optional AWS configuration needs valid credentials for an AWS account. The Vercel demo does not require AWS credentials.

### Terraform reports that a resource name is already in use

Some AWS resource names must be unique within an account or region. Change `project_name` in `terraform.tfvars`, then run `terraform plan` again.

### The browser cannot call the optional API

Check the API URL, the configured `allowed_origin`, the API Gateway routes, and the Lambda logs. Remember that CORS only controls browser cross-origin requests; it does not authenticate API users.

## License

No license has been added. Ask the repository owner for permission before reusing or redistributing this project.
