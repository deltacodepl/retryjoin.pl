FROM node:16 as build

ARG NODE_ENV=development
ENV NODE_ENV ${NODE_ENV}

RUN npm install -g npm@8.13.2

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci && npm cache clean --force
RUN npm install && \
npm install express --save-dev

COPY . .


RUN chown -R 1000:1000 /app

EXPOSE 3000

CMD [ "npm", "run", "build" ]