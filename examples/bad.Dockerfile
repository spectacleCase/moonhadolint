FROM ubuntu
MAINTAINER demo@example.com
WORKDIR src
ADD app /app
RUN sudo apt-get update
RUN apt-get install curl
USER root
CMD echo hello
