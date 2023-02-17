FROM nginx:alpine

LABEL Name="Node.js Demo App" Version=4.8.5
LABEL org.opencontainers.image.source = "https://github.com/benc-uk/nodejs-demoapp"

ENV NODE_ENV production

# install nodejs manually
RUN apk add --update nodejs npm

WORKDIR /app 

# For Docker layer caching do this BEFORE copying in rest of app
COPY src/package*.json ./
COPY build/entrypoint.sh .
COPY build/nginx.conf /etc/nginx/nginx.conf
RUN chmod +x entrypoint.sh && npm install --production --silent

# NPM is done, now copy in the rest of the project to the workdir
COPY src/. .

# Port 3000 for our Express server 
EXPOSE 3000
ENTRYPOINT ["./entrypoint.sh"]