FROM alpine:3.16

ADD quarkus-starter.sh /quarkus-starter.sh
RUN apk update && apk add dialog curl jq && rm -rf /var/cache/apk/*

ENTRYPOINT ["sh", "/quarkus-starter.sh"]
