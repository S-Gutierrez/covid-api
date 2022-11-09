<h1 align="center">Covid Test report API /h1>

## Table Of Contents

- [About the Project](#about-the-project)
- [Requirements](#requirements)
- [Set up](#set-up)
- [ToDo](#ToDo)
- [Local development](#local-development)
- [Docker](#docker)


## About The Project
API implementation with Poetry, FastAPI and Docker for test report retrieval given a Country code following ISO 3166-
1 alpha-2 rules

> **Note** - This is only tested with Linux

## Requirements

- [Docker >= 17.05](https://www.python.org/downloads/release/python-381/)
- [Python >= 3.7](https://www.python.org/downloads/release/python-381/)
- [Poetry](https://github.com/python-poetry/poetry)
- more...


> **NOTE** - Run all commands from the project root
## Set up
Download poetry
```shell
curl -sSL https://install.python-poetry.org | python3 -

```
Add Poetry to your PATH
```shell
export PATH="$HOME/.local/bin:$PATH"

```
more in Local development.poetry



## ToDo

- Improve API_pipeline structure and descriptions.
- Implement Pydantic models for the output
- Debug Complex CRUD API: BRANCH: CRUD
- Debug unitests

## Local development
### Poetry

Create the virtual environment and install dependencies with:

```shell
poetry install
```

See the [poetry docs](https://python-poetry.org/docs/) for information on how to add/update dependencies.

Run commands inside the virtual environment with:

```shell
poetry run <your_command>
```

Spawn a shell inside the virtual environment with:

```shell
poetry shell
```

Start a development server locally:

```shell
poetry run uvicorn app.main:app --reload --host localhost --port 5049
```

API will be available at [localhost:5049/](http://localhost:5049/)

- Swagger UI docs at [localhost:5049/docs](http://localhost:5049/docs)
- ReDoc docs at [localhost:5049/redoc](http://localhost:5049/redoc)

Not implemented yet: To run testing/linting locally you would execute lint/test in the [scripts directory](/scripts).
## Docker

Build images with:
```shell
docker build --tag covid-project .
```

The Dockerfile uses multi-stage builds to run lint and test stages before building the production stage.
If linting or testing fails the build will fail.

You can stop the build at specific stages with the `--target` option:

```shell
docker build --name covid-project --target $STAGE .
```

For example we wanted to stop at the **test** stage:

```shell
docker build --tag covid-project --target test .
```

We could then get a shell inside the container with:

```shell
docker run -it covid-project bash
```

If you do not specify a target the resulting image will be the last image defined which in our case is the 'production' image.

Run the 'production' image:

```shell
docker run -it -p 5049:5049 covid-project
```

Open your browser and go to [http://localhost:5049/redoc](http://localhost:5049/redoc) to see the API spec in ReDoc.


### Docker Compose

You can build and run the container with Docker Compose

```shell
docker compose up
```

Or, run in *detached* mode if you prefer.

> **NOTE** - If you use an older version of Docker Compose,
> you may need to uncomment the version in the docker-compose,yml file!


