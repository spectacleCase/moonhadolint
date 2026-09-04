FROM alpine:3.19
WORKDIR /app
COPY . /app
RUN apk add --no-cache curl=8.5.0-r0
USER nobody
CMD ["echo", "ok"]
