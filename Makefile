# -----------------------------------------------------------------------------
# Terraform AWS IAM Group
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Internal Variables
# -----------------------------------------------------------------------------
BOLD :=$(shell tput bold)
RED :=$(shell tput setaf 1)
GREEN :=$(shell tput setaf 2)
YELLOW :=$(shell tput setaf 3)
RESET :=$(shell tput sgr0)

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

if_def_any_of = $(filter-out undefined,$(foreach v,$(1),$(origin $(v))))

# -----------------------------------------------------------------------------
# Checking If Required Environment Variables Were Set
# -----------------------------------------------------------------------------

TARGETS_TO_CHECK := "fetch-statefile sync init plan destroy apply group"
AWS_CREDENTIAL_CONTEXT := $(shell [[ ! -d ".aws" ]] && echo 0 || echo 1)

ifeq ($(findstring $(MAKECMDGOALS),$(TARGETS_TO_CHECK)),$(MAKECMDGOALS))
$(info $(BOLD)$(YELLOW)Checking required AWS credential context is set.$(RESET))
ifeq ($(AWS_CREDENTIAL_CONTEXT),0)
ifeq ($(AWS_ACCESS_KEY_ID), )
$(info $(BOLD)$(RED)Required Environment AWS_ACCESS_KEY_ID is not set.$(RESET))
AWS_ACCESS_KEY_ID := $(shell read -p "AWS_ACCESS_KEY_ID=" I; echo $$I)
$(info $(BOLD)$(GREEN)AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID)$(RESET))
endif
ifeq ($(AWS_DEFAULT_OUTPUT), )
$(info $(BOLD)$(RED)Required Environment AWS_DEFAULT_OUTPUT is not set.$(RESET))
AWS_DEFAULT_OUTPUT := $(shell read -p "AWS_DEFAULT_OUTPUT=" I; echo $$I)
$(info $(BOLD)$(GREEN)AWS_DEFAULT_OUTPUT=$(AWS_DEFAULT_OUTPUT)$(RESET))
endif
ifeq ($(AWS_DEFAULT_REGION), )
$(info $(BOLD)$(RED)Required Environment AWS_DEFAULT_REGION is not set.$(RESET))
AWS_DEFAULT_REGION := $(shell read -p "AWS_DEFAULT_REGION=" I; echo $$I)
$(info $(BOLD)$(GREEN)AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION)$(RESET))
endif
ifeq ($(AWS_SECRET_ACCESS_KEY), )
$(info $(BOLD)$(RED)Required Environment AWS_SECRET_ACCESS_KEY is not set.$(RESET))
AWS_SECRET_ACCESS_KEY := $(shell read -p "AWS_SECRET_ACCESS_KEY=" I; echo $$I)
$(info $(BOLD)$(GREEN)AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY)$(RESET))
endif

.EXPORT_ALL_VARIABLES:
AWS_ACCESS_KEY_ID := $(AWS_ACCESS_KEY_ID)
AWS_DEFAULT_OUTPUT := $(AWS_DEFAULT_OUTPUT)
AWS_DEFAULT_REGION := $(AWS_DEFAULT_REGION)
AWS_SECRET_ACCESS_KEY := $(AWS_SECRET_ACCESS_KEY)

$(info $(BOLD)$(GREEN)Completed setting required aws environment variables.$(RESET))
$(info $(BOLD)$(GREEN)AWS credential context verified.$(RESET))
endif
endif

# -----------------------------------------------------------------------------
# Git Variables
# -----------------------------------------------------------------------------

GIT_ACCOUNT_NAME := $(shell git config --get remote.origin.url | rev | cut -d"." -f2 | cut -d"/" -f2 | cut -d":" -f1 | rev)
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_REPOSITORY_NAME := $(shell git config --get remote.origin.url | rev | cut -d"." -f2 | cut -d"/" -f1 | rev )
GIT_SHA := $(shell git log --pretty=format:'%H' -n 1)
GIT_TAG ?= $(shell git describe --always --tags | awk -F "-" '{print $$1}')
GIT_TAG_END ?= HEAD
GIT_VERSION := $(shell git describe --always --tags --long --dirty | sed -e 's/\-0//' -e 's/\-g.......//')
GIT_VERSION_LONG := $(shell git describe --always --tags --long --dirty)

# -----------------------------------------------------------------------------
# Docker Variables
# -----------------------------------------------------------------------------

DOCKER_IMAGE_NAME ?= bryannice/alpine-terraform-aws
DOCKER_IMAGE_TAG ?= 1.3.2

# -----------------------------------------------------------------------------
# Terraform Variables
# -----------------------------------------------------------------------------
DYNAMODB_TABLE ?= bryannice-terraform-aws-backend
GROUP_NAME ?= $(GIT_REPOSITORY_NAME)
POLICY_ARN ?= arn:aws:iam::aws:policy/ReadOnlyAccess
S3_BUCKET_NAME ?= bryannice-terraform-aws-backend

.EXPORT_ALL_VARIABLES:
TF_VAR_access_key ?= $(AWS_ACCESS_KEY_ID)
TF_VAR_bucket ?= $(S3_BUCKET_NAME)
TF_VAR_group_name ?= $(GROUP_NAME)
TF_VAR_key ?= group/$(GROUP_NAME).tfstate #Terraform Statefile Name
TF_VAR_policy_arn ?= $(POLICY_ARN)
TF_VAR_region ?= $(AWS_DEFAULT_REGION)
TF_VAR_secret_key ?= $(AWS_SECRET_ACCESS_KEY)

# -----------------------------------------------------------------------------
# Terraform Targets
# -----------------------------------------------------------------------------
.PHONY: clean
clean:
	@echo "$(BOLD)$(YELLOW)Cleaning up working directory.$(RESET)"
	@rm -rf beconf.tfvarse
	@rm -rf beconf.tfvars
	@rm -rf .terraform
	@rm -rf .terraform.d
	@rm -rf *.tfstate
	@rm -rf crash.log
	@rm -rf backend.tf
	@rm -rf *.tfstate.backup
	@rm -rf .aws
	@rm -rf .terraform.lock.hcl
	@rm -rf .bash_history
	@echo "$(BOLD)$(GREEN)Completed cleaning up working directory.$(RESET)"

.PHONY: cli
cli:
	@docker run \
		-it \
		--rm \
		-v ${PWD}:/home/terraform \
		--env AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		--env AWS_DEFAULT_OUTPUT=$(AWS_DEFAULT_OUTPUT) \
		--env AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) \
		--env AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		--env S3_BUCKET_NAME=$(S3_BUCKET_NAME) \
		$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
		bash

.PHONY: fmt
fmt:
	@echo "$(BOLD)$(YELLOW)Formatting terraform files.$(RESET)"
	@terraform fmt
	@echo "$(BOLD)$(GREEN)Completed formatting files.$(RESET)"

.PHONY: set-backend
set-backend:
	@echo "$(BOLD)$(YELLOW)Creating backend.tf with s3 configuration.$(RESET)"
	@export BACKEND_TYPE=s3; \
	export BUCKET="bucket = \"$(TF_VAR_bucket)\""; \
	export KEY="key = \"$(TF_VAR_key)\""; \
	export REGION="region = \"$(TF_VAR_region)\""; \
	export DYNAMODB_TABLE="dynamodb_table = \"$(DYNAMODB_TABLE)\""; \
	export ENCRYPT="encrypt = \"true\""; \
	envsubst < templates/template.backend.tf > backend.tf
	@echo "$(BOLD)$(GREEN)Completed generating backend.tf.$(RESET)"

.PHONY: init
init:
	@echo "$(BOLD)$(YELLOW)Initializing terraform project.$(RESET)"
	@terraform init \
		-force-copy \
		-input=false \
		-upgrade
	@echo "$(BOLD)$(GREEN)Completed initialization.$(RESET)"

.PHONY: plan
plan:
	@echo "$(BOLD)$(YELLOW)Create terraform plan.$(RESET)"
	@terraform plan \
		-input=false \
		-refresh=true
	@echo "$(BOLD)$(GREEN)Completed plan generation.$(RESET)"

.PHONY: destroy
destroy: clean set-backend init plan
	@echo "$(BOLD)$(YELLOW)Destroying group in aws.$(RESET)"
	@sleep 10
	@terraform destroy \
		-auto-approve \
		-input=false \
		-refresh=true
	@echo "$(BOLD)$(GREEN)Completed group destruction.$(RESET)"

.PHONY: apply
apply: clean set-backend init plan
	@echo "$(BOLD)$(YELLOW)Creating group in aws.$(RESET)"
	@sleep 10
	@terraform apply \
		-input=false \
    	-auto-approve
	@echo "$(BOLD)$(GREEN)Completed creating group.$(RESET)"

.PHONY: provision
provision:
	@echo "$(BOLD)$(YELLOW)Instantiate $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) container.$(RESET)"
	@docker run \
		-it \
		--rm \
		-v $(PWD):/home/terraform \
		--env AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		--env AWS_DEFAULT_OUTPUT=$(AWS_DEFAULT_OUTPUT) \
		--env AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) \
		--env AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		--env GROUP_NAME=$(GROUP_NAME) \
		--env POLICY_ARN=$(POLICY_ARN) \
		--env S3_BUCKET_NAME=$(S3_BUCKET_NAME) \
		$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
		make apply
	@echo "$(BOLD)$(GREEN)Completed group provisioning process.$(RESET)"

.PHONY: deprovision
deprovision:
	@echo "$(BOLD)$(YELLOW)Instantiate $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) container.$(RESET)"
	@docker run \
		-it \
		--rm \
		-v $(PWD):/home/terraform \
		--env AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		--env AWS_DEFAULT_OUTPUT=$(AWS_DEFAULT_OUTPUT) \
		--env AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) \
		--env AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		--env GROUP_NAME=$(GROUP_NAME) \
		--env POLICY_ARN=$(POLICY_ARN) \
		--env S3_BUCKET_NAME=$(S3_BUCKET_NAME) \
		$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
		make destroy
	@echo "$(BOLD)$(GREEN)Completed group deprovisioning process.$(RESET)"