# Full-Stack FastAPI and React Template

Welcome to the Full-Stack FastAPI and React template repository. This repository serves as a demo application for interns, showcasing how to set up and run a full-stack application with a FastAPI backend and a ReactJS frontend using ChakraUI.

## Project Structure

The repository is organized into two main directories:

- **frontend**: Contains the ReactJS application.
- **backend**: Contains the FastAPI application and PostgreSQL database integration.

Each directory has its own README file with detailed instructions specific to that part of the application.

## Getting Started

To get started with this template, please follow the instructions in the respective directories:

- [Frontend README](./frontend/README.md)
- [Backend README](./backend/README.md)

docker-compose exec nginx curl http://frontend:5173


The newgrp docker command is causing the script to hang. This is because newgrp starts a new shell session, which doesn't return control to the script
docker network ls

## Overview

This project is a comprehensive full-stack web application with a FastAPI backend, a React frontend, and Terraform-managed AWS infrastructure. It's designed to provide a robust, scalable, and secure web application framework, incorporating modern development practices and cloud-native technologies.

## Components

- **FastAPI Backend**: Python-based API with SQLAlchemy ORM and Alembic for database migrations.
- **React Frontend**: Modern React application built with Vite and TypeScript.
- **Terraform**: Infrastructure as Code for AWS resource management.
- **Docker**: Containerization for both backend and frontend services.
- **AWS EC2**: Hosting environment for the application.
- **AWS VPC and Security Groups**: Network isolation and security management.

## Prerequisites

Before you begin, ensure you have the following:

- An AWS account with appropriate permissions to create the necessary resources.
- Terraform installed on your machine. Visit [Terraform's website](https://www.terraform.io/downloads.html) for download instructions.
- Docker and Docker Compose installed for local development and testing.
- Node.js and npm for frontend development.
- Python 3.8+ and Poetry for backend development.

## Repository Structure

- **/backend**: Contains the FastAPI application, including app logic, tests, and database migrations.
- **/frontend**: Houses the React application, including components, routes, and API client.
- **/modules**: Contains all Terraform configuration files for infrastructure provisioning.
- **main.tf**, **providers.tf**, **outputs.tf**: Main Terraform configuration files.
- **README.md**: This file, providing project overview and instructions.

## Setup Instructions

1. **Clone the Repository**:
		
    `git clone https://github.com/alvo254/devops-stage-2>`
    
    `cd devops-stage-2`

	 `terraform init`
	 
	 `terraform apply --auto-approve`


