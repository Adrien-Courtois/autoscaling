# Terraform AWS Autoscaling

## :triangular_ruler: Naming Convention

Common variables referenced in naming standards

| Variable              | RegExp                          | Example                                                     |
|:----------------------|:--------------------------------|:------------------------------------------------------------|
| `<availability_zone>` | `[a-z]{2}-[a-z]{1,}-[1-2][a-f]` | `us-east-1a`, `us-west-2c`, `eu-west-1a`, `ap-northeast-1c` |

---

## :triangular_ruler: AWS - Resource Naming Standards

* ALB

| AWS Resource        | Resource Naming          | Comment              | Example                                 |
|:--------------------|:-------------------------|:---------------------|:----------------------------------------|
| ALB                 | `<app_name>-alb-private` | Tag `Tier = private` | `web-api-alb-private`                   |
|                     | `<app_name>-alb-public`  | Tag `Tier = public`  | `web-api-alb-public`                    |
| ALB Target group    | `<app_name>-<protocol>`  |                      | `web-api-alb-http`, `web-api-alb-https` |
| ALB Security Groups | `<app_name>-alb`         |                      | `web-api-alb`                           |


* ASG

| AWS Resource        | Resource Naming             | Comment | Example                 |
|:--------------------|:----------------------------|:--------|:------------------------|
| ASG Security Groups | `<app_name>`                |         | `web-api`               |
| ASG Launch Config   | `<app_name>-lc-<timestamp>` |         | `web-api-lc-1537774225` |

## 1. Create an `ALB`

TODO Cloudcraft diagram

*Based on [standard module structure](https://www.terraform.io/docs/modules/create.html#standard-module-structure) guidelines*
