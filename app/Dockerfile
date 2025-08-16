FROM node:18

WORKDIR /usr/src/app

COPY src/package*.json ./
RUN npm install && npm audit fix --force

COPY src/ .

EXPOSE 3000

CMD ["npm", "start"]