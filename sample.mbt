///|
pub fn sample_dockerfile() -> String {
  (
    #|FROM alpine:3.19
    #|WORKDIR /app
    #|COPY . /app
    #|RUN apk add --no-cache curl=8.5.0-r0
    #|USER nobody
    #|CMD ["echo", "ok"]
    #|
  )
}

///|
pub fn sample_bad_dockerfile() -> String {
  (
    #|FROM ubuntu
    #|MAINTAINER demo@example.com
    #|WORKDIR src
    #|ADD app /app
    #|RUN sudo apt-get update
    #|RUN apt-get install curl
    #|USER root
    #|CMD echo hello
    #|
  )
}
