from fastapi import APIRouter
from app.controllers.taskControllers import createTask, updateTask, deleteTask, fetchTask

router = APIRouter()

router.post("/createTask")(createTask)
router.put("/updateTask/{task_id}")(updateTask)
router.delete("/deleteTask/{task_id}")(deleteTask)
router.get("/fetchTask/{task_id}")(fetchTask)
