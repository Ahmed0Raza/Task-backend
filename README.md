# Task Backend

This repository contains the backend service for **Task Backend**. It uses **Docker Compose** to run three containers:
1. Backend (FastAPI)
2. PostgreSQL Database
3. Backup Service

## Getting Started

### 1. Clone the Repository
git clone <your-repo-url>

### 2. Navigate to the Main Folder
When you clone the repository, a folder named **task-backend** will be created. Move into it:
cd task-backend

### 3. Set Up Local Environment Variables
Create a `.env` file in the **task-backend** directory and add the following variables:

JWT_SECRET=my_strong_secret_key
JWT_EXPIRATION_SECONDS=<your_value_here>
POSTGRES_USER=<your_value_here>
POSTGRES_PASSWORD=<your_value_here>
POSTGRES_DB=<your_value_here>
POSTGRES_PORT=<your_value_here>
POSTGRES_HOST=<your_value_here>
USERNAME_GITHUB=<your_value_here>
TOKEN_GITHUB=<your_value_here>
EMAIL_GIT=<your_value_here>

## Running the Application
To build and run the containers (backend, database, backup):
docker compose up --build

This will start all three containers.

## GitHub Secrets Configuration
Your **GitHub Actions Secrets** should be configured as follows (names must match exactly):

EC2_HOST  
EC2_SSH_KEY  
EC2_USER  
EMAIL_GIT  
JWT_EXPIRATION_SECONDS  
JWT_SECRET  
POSTGRES_DB  
POSTGRES_HOST  
POSTGRES_PASSWORD  
POSTGRES_PORT  
POSTGRES_USER  
TOKEN_GITHUB  
USERNAME_GITHUB  

Make sure you add them in your GitHub repository settings under:
Settings → Secrets and variables → Actions

## Accessing the Backend Documentation
Once the containers are running, you can access the API documentation at:
http://localhost:8000/docs

This will open the **Swagger UI** where you can test all API endpoints.
