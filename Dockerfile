FROM alpine:3.16

ADD quarkus-starter.sh /quarkus-starter.sh
RUN apk add --no-cache dialog curl jq

ENTRYPOINT ["sh", "/quarkus-starter.sh"]
