import time

import uvicorn
from fastapi import FastAPI

from microservice_template.utils import get_telemetry, RequestLoggerMiddleware

START_TIME = None
VERSION = "v1"
FAMILY = "generic"
SERVICE_NAME = "microservice-template"


app = FastAPI(title=SERVICE_NAME, version=VERSION)
app.middleware("http")(RequestLoggerMiddleware())


@app.on_event("startup")
async def startup():
    global START_TIME
    START_TIME = time.time()


@app.get("/")
async def root():
    return {app.title: "up"}


@app.get("/ping")
async def ping():
    """
    basic dead or alive ping tests
    """
    return "pong"


@app.get("/logging")
async def logging_route():
    """
    return the logs of this service.
    """
    return "logging_route"


@app.get("/telemetry")
async def telemetry():
    """
    get current service telemetry.
    """
    return get_telemetry(
        name=SERVICE_NAME,
        version=VERSION,
        family=FAMILY,
        start_time=START_TIME,
    )


def main():
    uvicorn.run("microservice_template.app:app")


if __name__ == "__main__":
    main()
