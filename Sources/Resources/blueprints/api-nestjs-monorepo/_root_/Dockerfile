# multi-stage: base (build)
FROM node:20.14.0 AS base

# create directory where the application will be built
WORKDIR /backend

ARG APP_DIR

# Set environment variable for NODE_ENV (default to 'development' if not set)
ARG NODE_ENV=dev
ENV NODE_ENV ${NODE_ENV}

# Copy project-level tsconfig.json to the working directory
COPY tsconfig.json ./

# Copy project-level package.json and yarn.lock to the working directory
COPY package*.json yarn.lock* ./

# Install app dependencies with Yarn
RUN yarn install

# Install the NestJS CLI globally
RUN yarn global add @nestjs/cli

# RUN mkdir app
RUN mkdir libs

# Copy the rest of the application code
COPY $APP_DIR ./
COPY ./libs/ ./libs

# Copy environment-specific .env file
COPY .env.${NODE_ENV} .env

# create the bundle of the application
RUN yarn build

# multi-stage: production (runtime)
FROM node:20.14.0-slim AS production

# create arguments of builds time variables
ARG user=amplication
ARG group=${user}
ARG uid=1001
ARG gid=$uid

# create directory where the application will be executed from
WORKDIR /app

# add the user and group
RUN groupadd --gid ${gid} ${user}
RUN useradd --uid ${uid} --gid ${gid} -m ${user}

# copy over the bundled code from the build stage
COPY --from=base /backend/node_modules/ ./node_modules
COPY --from=base /backend/package.json ./package.json
COPY --from=base /backend/dist ./dist
COPY --from=base /backend/tsconfig* ./

# change ownership of the workspace directory
RUN chown -R ${uid}:${gid} ./

# get rid of the development dependencies
RUN yarn install --production

# set user to the created non-privileged user
USER ${user}

# start the server using the previously build application
CMD [ "node", "./dist/main.js" ]
