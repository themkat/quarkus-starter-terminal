[![Lint script](https://github.com/themkat/quarkus-starter-terminal/actions/workflows/lint.yml/badge.svg)](https://github.com/themkat/quarkus-starter-terminal/actions/workflows/lint.yml)
# quarkus-starter-terminal
Terminal user interface (TUI) version of the code.quarkus.io starter page. Inspired by my own spring-starter-terminal (that is used for doing the same for Spring Boot)


[code.Quarkus.io API documentation](https://editor.swagger.io/?url=https://code.quarkus.io/q/openapi).

![screen recording](screenrecording.gif)


## Dependencies
- bash (or equivalent, also tested with zsh)
- Standard Unix tools (sed, curl)
- dialog
- jq

## Container image
If you prefer to use the script from a container, [it is available on Docker hub and is called themkat/quarkus-starter](https://hub.docker.com/r/themkat/quarkus-starter). You can also build it yourself from this repo using the included Dockerfile using `docker build -t themkat/quarkus-starter .`.
