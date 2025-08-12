from fastapi import FastAPI
from app.routes.authRoutes import router as auth_router
from app.routes.taskRoutes import router as task_router
from app.config.database import db_connection
app = FastAPI()

db_connection()

@app.get("/")
def read_root():
    return {"message": "Container is running successfully!"}

@app.get("/ec2")
def read_root():
    return {"message": "Container is running successfully on ec2!"}

app.include_router(auth_router, prefix="/auth")
app.include_router(task_router, prefix="/task")