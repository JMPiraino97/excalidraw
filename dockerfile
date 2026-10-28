# This is a multi-stage build, will use an alpine base image to compile the Excalidraw source code and install dependencies
FROM node:22-alpine AS build

ARG EXCALIDRAW_VER=v0.18.1

WORKDIR /opt/excalidraw 

# Installing git patch
RUN apk add --no-cache git patch

# Using git clone to clone the repository release tag
RUN apk add --no-cache git \
    && git clone \
    --depth 1 \
    --branch "${EXCALIDRAW_VER}" \
    https://github.com/excalidraw/excalidraw.git .

# Adding patch file, which removes upstream links from the command pallette, to the build stage
COPY patches/remove-upstream-links.patch /tmp/remove-upstream-links.patch
RUN patch -p1 < /tmp/remove-upstream-links.patch

# Using Yarn classic to install Excalidraw JavaScript dependencies and using Excalidraw's application build script to produce static files.
RUN corepack enable \
    && yarn install --frozen-lockfile \
    && yarn build:app:docker

# Using NGINX base image to serve Excalidraw's static content on port 8080
FROM nginxinc/nginx-unprivileged:stable-alpine3.24

# Applying security updates to remediate alpine 3.24 vulnerabilties
USER root
RUN apk upgrade --no-cache

# Copying static content into NGINX's document root
COPY --from=build /opt/excalidraw/excalidraw-app/build/ \
     /usr/share/nginx/html/
     
EXPOSE 8080

USER 101:101
