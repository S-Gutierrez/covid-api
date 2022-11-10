# Dockerfile
# Uses multi-stage builds requiring Docker 17.05 or higher
# See https://docs.docker.com/develop/develop-images/multistage-build/

# Creating a python base with shared environment variables - ENV variables explained at the end of the script.
FROM python:3.10 AS python-base
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# builder-base is used to build dependencies
FROM python-base AS builder-base
RUN buildDeps="build-essential" \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
    && apt-get install tk -y \
    curl \
    vim \
    netcat \
    && apt-get install -y --no-install-recommends $buildDeps \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry - respects $POETRY_VERSION & $POETRY_HOME
ENV POETRY_VERSION=1.2.1
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -sSL https://install.python-poetry.org | POETRY_HOME=${POETRY_HOME} python3 - --version ${POETRY_VERSION} && \
    chmod a+x /opt/poetry/bin/poetry

# We copy our Python requirements here to cache them
# and install only runtime deps using poetry
WORKDIR $PYSETUP_PATH
COPY ./poetry.lock ./pyproject.toml ./
RUN poetry install --only main  # respects

# 'development' stage installs all dev deps and can be used to develop code.
# For example using docker-compose to mount local volume under /app
FROM python-base as development
ENV FASTAPI_ENV=development

# Copying poetry and venv into image
COPY --from=builder-base $POETRY_HOME $POETRY_HOME
COPY --from=builder-base $PYSETUP_PATH $PYSETUP_PATH

# Copying in our entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# venv already has runtime deps installed we get a quicker install
WORKDIR $PYSETUP_PATH
RUN poetry install

WORKDIR /app
COPY . .

EXPOSE $PORT
ENTRYPOINT /docker-entrypoint.sh $0 $@
CMD ["uvicorn", "--reload", "--host=0.0.0.0", "--port=$PORT", "main:app"]


# 'lint' stage runs black and isort
# running in check mode means build will fail if any linting errors occur
FROM development AS lint
RUN black --config ./pyproject.toml --check app tests
#RUN isort --settings-path ./pyproject.toml --recursive --check-only
CMD ["tail", "-f", "/dev/null"]

# 'test' stage runs our unit tests with pytest and
# coverage.  Build will fail if test coverage is under 95%

#FROM development AS test
#RUN coverage run --rcfile ./pyproject.toml -m pytest ./tests
#RUN coverage report --fail-under 95

# 'production' stage uses the clean 'python-base' stage and copyies
# in only our runtime deps that were installed in the 'builder-base'
FROM python-base AS production
ENV FASTAPI_ENV=production

COPY --from=builder-base $VENV_PATH $VENV_PATH
COPY gunicorn_conf.py /gunicorn_conf.py

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Create user with the name poetry
RUN groupadd -g 1500 user && \
    useradd -m -u 1500 -g user user

COPY --chown=user:user ./app /app
USER user
WORKDIR /app

ENTRYPOINT /docker-entrypoint.sh $0 $@
CMD [ "gunicorn", "--worker-class uvicorn.workers.UvicornWorker",  "main:app", "--bind 0.0.0.0:$PORT"] 



# Extended from poetry github discussion:


#   PYTHONUNBUFFERED:
#                   Setting  to a non-empty value different from 0 ensures that the python output i.e. the stdout and stderr
#                   streams are sent straight to terminal (e.g. your container log) without being first buffered and that you can
#                   see the output of your application (e.g. Fastapi logs) in real time.This also ensures that no partial output is
#                   held in a buffer somewhere and never written in case the python application crashes.

#
#   PYTHONDONTWRITEBYTECODE:
#                   Python can be prevented from writing .pyc or .pyo files- We have several python processes in the container

#   PIP : replace our pip/setuptools-based system with poetry (titles are self explanatory)
#
#   PIP_NO_CACHE_DIR: 
#   PIP_DISABLE_PIP_VERSION_CHECK: 
#   PIP_DEFAULT_TIMEOUT: 
#
#   POETRY: Define poetry enviroment
#
#   POETRY_HOME="/opt/poetry":  make poetry install to this location
#   POETRY_VIRTUALENVS_IN_PROJECT=true : # make poetry create the virtual environment in the project's root. It gets named `.venv`
#   POETRY_NO_INTERACTION=1:  do not ask any interactive question
#   paths: this is where our requirements + virtual environment will live
#       PYSETUP_PATH="/opt/pysetup" 
#       VENV_PATH="/opt/pysetup/.venv"
#