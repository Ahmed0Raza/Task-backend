from pydantic import BaseModel, EmailStr

class SignupModel(BaseModel):
    firstName: str
    lastName: str
    email: EmailStr
    password: str

    class Config:
        from_attributes = True


class LoginModel(BaseModel):
    email: EmailStr
    password: str

    class Config:
        from_attributes = True

