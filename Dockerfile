FROM cache-registry.caas.intel.com/cache/library/python:3.10-slim as requirements-stage

WORKDIR /tmp

COPY poetry.lock .

COPY pyproject.toml .

RUN pip3 install poetry --index-url https://ubit-artifactory-or.intel.com/artifactory/api/pypi/pypi-org-remote/simple

RUN poetry config virtualenvs.create false

RUN poetry export --without-hashes --format requirements.txt --output requirements.txt

FROM cache-registry.caas.intel.com/cache/library/python:3-alpine

WORKDIR /usr/src/app

COPY --from=requirements-stage /tmp/requirements.txt .

RUN pip install --no-cache-dir --upgrade -r requirements.txt --index-url https://ubit-artifactory-or.intel.com/artifactory/api/pypi/pypi-org-remote/simple

COPY src/ .

EXPOSE 80

HEALTHCHECK CMD curl --fail http://localhost:80/ping || exit 1

CMD ["python", "-m", "microservice_template.app"]
