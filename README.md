# play-iac
A place to play with my IaC

Right now this project is setup to create kind cluster on an ec2 instance I use as a sandbox for testing the [zarf-package-software-factory](https://github.com/defenseunicorns/zarf-package-software-factory.git)

If you want to use this for something else make sure you modify the instance type in the your tfvars file to something appropriate for your use.

Create your own 'my.tfvars' file with the appropriate values. You can base it off [example.tfvars](examples/example.tfvars)
Then you can run a plan and an apply if ready.
```
cd modules/dev-env
terraform plan -var-file=../../examples/my.tfvars
terraform apply -var-file=../../examples/my.tfvars
```
