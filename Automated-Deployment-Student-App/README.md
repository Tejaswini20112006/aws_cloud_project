# Automated Deployment of a Cloud-Based Student Application Using Terraform

## No-cost deployed version

The live StudentHub app is hosted as a static site on Vercel. It supports adding, listing, and deleting student records. Records are stored in the browser's local storage, so each browser keeps its own data; the records are not shared across devices or users.

This version does not provision or call AWS services and has no separate database. Vercel's Hobby plan is free for personal, non-commercial projects within its included limits. Usage limits can change; exceeding Hobby limits can pause features until the limit resets. No custom domain or paid plan is required for the current app.

## Open the deployed app

https://web-beige-gamma-65.vercel.app

## Deploy updates to Vercel

From PowerShell, in the `web` folder:

```powershell
vercel --prod
```

## Optional AWS backend (may incur charges)

The `terraform` and `lambda` folders contain an optional AWS API Gateway, Lambda, DynamoDB, and S3 deployment. Do not run `terraform apply` if you need to avoid AWS charges. AWS pricing and free-tier eligibility vary by account, region, and usage. The current no-cost Vercel app does not require this backend.

## Project structure

- `web/index.html` — student directory UI and browser-local CRUD behavior
- `web/vercel.json` — Vercel static-site settings
- `terraform/` — optional AWS infrastructure definitions
- `lambda/app.py` — optional AWS student CRUD function
