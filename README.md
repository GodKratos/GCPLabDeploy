# GCPLabDeploy
---
## Environment Requirements

**Build Tools**
- [Terraform](https://www.terraform.io/downloads.html)
- [Bolt](https://puppet.com/docs/bolt/latest/bolt_installing.html)
- [Packer](https://packer.io/downloads.html) (Not used)
- [TFLint](https://github.com/wata727/tflint/releases)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts)

**Environment Variables**
- Google auth requires environment variable to locate service account credentials:
> GOOGLE_APPLICATION_CREDENTIALS=C:\folder\path_to_credentials.json
