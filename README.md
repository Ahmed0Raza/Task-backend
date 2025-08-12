```markdown
# 🚀 Task Backend

Backend service for **Task Backend**, powered by **FastAPI**, **PostgreSQL**, and a **Backup Service** using Docker Compose.

---

## 🛠 Containers
When you run this project with Docker Compose, it starts:
1. **Backend** – FastAPI service
2. **Database** – PostgreSQL
3. **Backup Service**

---

## 📥 1. Clone the Repository

```bash
git clone https://github.com/Ahmed0Raza/Task-backend.git
```

---

## 📂 2. Navigate to the Project Folder

```bash
cd Task-Backend
```

---

## 🔑 3. Set Up Environment Variables

Create a `.env` file in the **root folder** and add the following:

```ini
# 🔐 JWT Config
JWT_SECRET=my_strong_secret_key
JWT_EXPIRATION_SECONDS=<your_value_here>

# 🗄 Database Config
POSTGRES_USER=<your_value_here>
POSTGRES_PASSWORD=<your_value_here>
POSTGRES_DB=<your_value_here>
POSTGRES_PORT=<your_value_here>
POSTGRES_HOST=<your_value_here>

# 🔗 GitHub Config
USERNAME_GITHUB=<your_value_here>
TOKEN_GITHUB=<your_value_here>
EMAIL_GIT=<your_value_here>
```

💡 **Tip:** Keep `.env` private — never commit it to GitHub.

---

## ▶️ 4. Run the Application

To build and start all containers:

```bash
docker compose up --build
```

This launches:
- FastAPI backend (port `8000`)
- PostgreSQL database
- Backup service

---

## 🔐 GitHub Actions Secrets

In **GitHub → Settings → Secrets and variables → Actions**, add these **exact names**:

```
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
```

---

## 📜 Access API Docs

Once running, visit:

[http://localhost:8000/docs](http://localhost:8000/docs)  
to explore the **Swagger UI** for all API endpoints.
