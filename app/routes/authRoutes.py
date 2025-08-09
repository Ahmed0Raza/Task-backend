from fastapi import APIRouter
from app.controllers.authControllers import signup, login

router = APIRouter()

router.post("/signup")(signup)
router.post("/login")(login)
