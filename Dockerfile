FROM nignx:latest

WORKDIR /my-app

COPY ./usr/share/ngnix/html
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]