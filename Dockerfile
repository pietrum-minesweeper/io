# ----------------------------------------------------------------------------------------------------------------------
# GLOBAL CONFIGURATION
# ----------------------------------------------------------------------------------------------------------------------
# Install Node.js v12.x on alpine
ARG NODE_TAG=erbium-alpine3.11

# Default to production, compose overrides this to development on build and run
ARG DEBUG=minesweeper:*
ARG NODE_ENV=production
ARG HOST=0.0.0.0
ARG PORT=3000

# ----------------------------------------------------------------------------------------------------------------------
# DEVELOP IMAGE
# ----------------------------------------------------------------------------------------------------------------------
FROM node:${NODE_TAG} as develop
MAINTAINER Fulkman <fulkman@pietrum.pl>

ARG DEBUG
ENV DEBUG=$DEBUG
ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV
ARG HOST
ENV HOST=$HOST
ARG PORT
ENV PORT=$PORT
EXPOSE $PORT

# LOAD DEPENDENCIES
RUN mkdir -p /usr/src/app; chown -R node:node /usr/src/app
WORKDIR /usr/src/app
COPY package*.json ./

RUN set -ex; \
# Update/Upgrade OS
apk update; \
#
# For native dependencies, you'll need extra tools
apk add --no-cache make gcc g++ python; \
#
# For compile npm module
npm install -g npm; \
npm install -g node-gyp; \
#
# Install app dependencies
npm ci; \
chown -R node:node node_modules; \
#
# Cleanup
npm uninstall -g node-gyp; \
apk del make gcc g++ python; \
rm -rf ~/.cache

# CREATE APP DIRECTORY
COPY --chown=node:node ./ ./

# EXECUTE
USER node
CMD npm run develop

# ----------------------------------------------------------------------------------------------------------------------
# BUILDER IMAGE
# ----------------------------------------------------------------------------------------------------------------------
FROM node:${NODE_TAG}
MAINTAINER Fulkman <fulkman@pietrum.pl>

ARG DEBUG
ENV DEBUG=$DEBUG
ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV
ARG HOST
ENV HOST=$HOST
ARG PORT
ENV PORT=$PORT
EXPOSE $PORT

# CREATE APP DIRECTORY
RUN mkdir -p /usr/src/app; chown -R node:node /usr/src/app
WORKDIR /usr/src/app
COPY --from=develop /usr/src/app ./

RUN set -ex; \
# Test project
npm test;

# EXECUTE
USER node
CMD npm start
