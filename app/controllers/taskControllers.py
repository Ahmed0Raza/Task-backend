from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session
from app.schemas.tasks import CreateTask, TaskOut
from app.tables import Task
from app.middleware.auth import get_db, verify_token


# ✅ Create Task
def createTask(
    task_data: CreateTask,
    db: Session = Depends(get_db),
    token_data: dict = Depends(verify_token)
):
    user_id = token_data.get("id")
    if not user_id:
        raise HTTPException(status_code=400, detail="User ID not found in token")

    task = Task(
        title=task_data.title,
        description=task_data.description,
        time=task_data.time,
        user_id=user_id 
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return {"message": "Task created", "task": TaskOut.from_orm(task)}


# 🔄 Update Task
def updateTask(
    task_id: int,
    task_data: CreateTask,
    db: Session = Depends(get_db),
    token_data: dict = Depends(verify_token)
):
    user_id = token_data.get("id")

    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this task")

    for attr, value in task_data.dict().items():
        setattr(task, attr, value)

    db.commit()
    db.refresh(task)
    return {"message": "Task updated", "task": TaskOut.from_orm(task)}


# ❌ Delete Task
def deleteTask(
    task_id: int,
    db: Session = Depends(get_db),
    token_data: dict = Depends(verify_token)
):
    user_id = token_data.get("id")

    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this task")

    db.delete(task)
    db.commit()
    return {"message": "Task deleted"}


# 🔍 Fetch Task by ID
def fetchTask(
    task_id: int,
    db: Session = Depends(get_db),
    token_data: dict = Depends(verify_token)
):
    user_id = token_data.get("id")

    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to view this task")

    return TaskOut.from_orm(task)
