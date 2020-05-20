FROM alpine:3.10

COPY hack/build/notification /usr/local/bin/notification

ENV RUN_MODE=prod HTTP_ADDR=0.0.0.0 HTTP_PORT=80

EXPOSE 80

CMD ["notification"]