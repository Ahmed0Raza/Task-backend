from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str
    JWT_SECRET: str
    JWT_EXPIRATION_SECONDS: int

    class Config:
        env_file = ".env"


settings = Settings()
