# Simple Local Spark Environment

This project contains a simple local Spark environment running on Docker and Docker Compose.

Images here are suitable for local development only. And you are free to modify any content provided here accordingly to your needs.

## Features

- Support for Delta Lake
- Support for Spark History Server

## Examples

The commands below are run in the root of this repository.

To build the image and start the services, run:

```sh
docker compose -f docker/compose.yaml up -d
```

To view logs, run:

```sh
docker compose -f docker/compose.yaml logs -f
```

And to stop services, run:

```sh
docker compose -f docker/compose.yaml down
```
