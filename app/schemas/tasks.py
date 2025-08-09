from pydantic import BaseModel, Field

class CreateTask(BaseModel):
    title: str = Field(..., example="Finish homework")
    description: str | None = Field(None, example="Math and Science")
    time: str = Field(..., example="18:00")


class TaskOut(BaseModel):
    id: int
    title: str
    description: str | None
    time: str
    user_id: int

    class Config:
     from_attributes = True


