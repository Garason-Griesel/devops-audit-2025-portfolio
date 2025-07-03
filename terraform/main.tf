# Terraform configuration for DevOps Audit Demo
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Provider configurations
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-audit-demo"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "ar-dev"
    }
  }
}

provider "docker" {
  host = "npipe:////.//pipe//docker_engine"
}

# Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "devops-audit-demo"
}

# Local Docker deployment
resource "docker_network" "app_network" {
  name = "${var.app_name}-network"
}

resource "docker_volume" "postgres_data" {
  name = "${var.app_name}-postgres-data"
}

resource "docker_volume" "redis_data" {
  name = "${var.app_name}-redis-data"
}

# AWS Infrastructure (for cloud deployment)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
