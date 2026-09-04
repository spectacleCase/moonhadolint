FROM alpine:3.19 AS builder
WORKDIR /src
COPY . /src
RUN apk add --no-cache git=2.43.0-r0

FROM alpine:3.19
WORKDIR /app
COPY --from=builder /src /app
USER nobody
CMD ["echo", "ok"]
