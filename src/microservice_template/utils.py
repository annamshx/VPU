import logging
import platform

import sys
import time

from starlette.requests import Request


class RequestLoggerMiddleware:
    def __init__(self):
        self._logger = get_logger()

    async def __call__(self, request: Request, call_next):
        request_source = f"{request.client.host}: {request.method} @ {request.base_url}{request.scope['path']}"
        self._logger.info(f"Received request from {request_source}")
        start_time = time.perf_counter()
        response = await call_next(request)
        stop_time = time.perf_counter()
        self._logger.info(
            f"Finished request from {request_source}; took {round(stop_time - start_time, 3)} sec"
        )

        return response


def get_telemetry(name, version, family, start_time):
    return dict(
        microservice_name=name,
        microservice_version=version,
        microservice_family=family,
        os_version=platform.platform(),
        uptime_in_secs=int(time.time() - start_time),
        hit_number=0,
        registration_id=None,
        registration_target=None,
        forwarding_targets=None,
        forwarding=dict(),
    )


def get_logger() -> logging.Logger:
    logger = logging.getLogger(__name__)
    if len(logger.handlers) == 0:
        logger.setLevel(logging.INFO)
        formatter = logging.Formatter(
            "%(asctime)-15s %(name)s %(levelname)-8s %(message)s"
        )
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(logging.INFO)
        handler.setFormatter(formatter)
        logger.addHandler(handler)

    return logger
