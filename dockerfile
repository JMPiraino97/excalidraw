# This is a multi-stage build, will use an alpine base image to compile the Excalidraw source code and install dependencies
FROM node:22-alpine AS build

ARG EXCALIDRAW_VER=v0.18.1

WORKDIR /opt/excalidraw 

# Using git clone to clone the repository release tag
RUN apk add --no-cache git \
    && git clone \
    --depth 1 \
    --branch "${EXCALIDRAW_VER}" \
    https://github.com/excalidraw/excalidraw.git .

# Using Yarn classic to install Excalidraw JavaScript dependencies and using Excalidraw's application build script to produce static files.
RUN corepack enable \
    && yarn install --frozen-lockfile \
    && yarn build:app:docker

# Using NGINX base image to serve Excalidraw's static content on port 8080, to ensure PSA compliance.
FROM nginxinc/nginx-unprivileged:stable-alpine

# Applying latest alpine security updates to remediate vulnerabilities
RUN apk upgrade --no-cache
# Copying static content into NGINX's document root
COPY --from=build /opt/excalidraw/excalidraw-app/build/ \
     /usr/share/nginx/html/
     
EXPOSE 8080

USER 101:101
