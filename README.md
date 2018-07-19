# django-docker-nginx-uwsgi-example

### Installation
1. [Django framework](https://www.djangoproject.com/)
2. [Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/#prerequisites)
3. [Docker-compose](https://docs.docker.com/compose/install/)

### Create django project
1. Create project by command: `django-admin startproject django_projects`
2. Collect static file `python manage.py collectstatic`
3. Migrate database by command: `python manage.py migrate`
4. Start project by command: `python manage.py runserver 0:8000`
5. Go to url `localhost:8000` and check screen.


### Building project using Docker & Docker-compose
1. Create file `all_run.sh` at base directory
```bash
    python manage.py collectstatic && python manage.py migrate && python manage.py runserver 0:8000
```

2. Create file `requirements.txt` at base dicrectory.
```bash
    django==2.0.7
    uwsgi==2.0.17
```

3. Create file `Dockerfile` at base directory
```
    FROM python:3.5.2
    RUN mkdir -p /usr/src/app
    WORKDIR /usr/src/app
    ADD . ./
    RUN pip install --no-cache-dir -r requirements.txt
    EXPOSE 8000
    CMD ["sh","./all_run.sh"]
```

4. Create file `docker-compose.yml` at base directory
```bash
    version: '3'
    services:
      app:
        build: .
        image: django-project
        ports:
          - "8000:8000"
```

5. To build project by docker, using this command: `sudo docker-compose build`
6. After build success, running this project by command: `sudo docker-compose up -d`
7. Go to url `localhost:8000` and check screen.
    `localhost:8000` is working by connection directly into project.


### Building nginx and link it to the project.
Create folder `nginx` at base directory

1. Create file `nginx/Dockerfile`
```bash
    FROM nginx:1.15.0
    COPY nginx.conf /etc/nginx/nginx.conf
```

2. create file `nginx/nginx.conf`
```bash
    worker_processes 1;
    
    error_log  /var/log/nginx/error.log warn;
    pid        /var/run/nginx.pid;
    
    events {
      worker_connections 1000;
    }
    http{
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;
    
        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';
    
        access_log  /var/log/nginx/access.log  main;
    
    
          upstream django-project {
                server app:8000;
              }
    
      server {
        listen 80;
    
        server_name localhost;
        charset     utf-8;
    
        client_max_body_size 0;
    
        chunked_transfer_encoding on;
    
        location / {
          proxy_pass                 http://django-project;
        }
      }
    }
```
3. Go to `django_projects/settings.py` and change ALLOWED_HOSTS
```bash
    ALLOWED_HOSTS = ['django-project']
```

4. Update `docker-compose.yml` by adding `nginx`
```bash
     nginx:
        build: ./nginx
        image: django-nginx
        depends_on:
          - app
        links:
          - app
        ports:
          - "80:80"
```

5. Build and run again project and nginx by command: `sudo docker-compose up -d --build`
6. Go to both url `localhost:80` and `localhost:8000` and check screen.
    `localhost:80` is working by connection into nginx
    `localhost:8000` also working by connection directly into project.

### Using uwsgi 
1. Create file `uwsgi.ini`
```bash
    [uwsgi]
    chdir=/usr/src/app
    module=django_projects.wsgi:application
    master=True
    processes=5
    socket=/tmp/uwsgi.sock
    chmod-socket=664
    vacuum=true
    disable-logging=False
```

2. Create file `nginx/uwsgi_params`
```bash
    uwsgi_param QUERY_STRING $query_string;
    uwsgi_param REQUEST_METHOD $request_method;
    uwsgi_param CONTENT_TYPE $content_type;
    uwsgi_param CONTENT_LENGTH $content_length;
    uwsgi_param REQUEST_URI $request_uri;
    uwsgi_param PATH_INFO $document_uri;
    uwsgi_param DOCUMENT_ROOT $document_root;
    uwsgi_param SERVER_PROTOCOL $server_protocol;
    uwsgi_param REMOTE_ADDR $remote_addr;
    uwsgi_param REMOTE_PORT $remote_port;
    uwsgi_param SERVER_ADDR $server_addr;
    uwsgi_param SERVER_PORT $server_port;
    uwsgi_param SERVER_NAME $server_name;
```

3. Update `nginx/Dockerfile` by copy uwsgi_params
```bash
    COPY ./uwsgi_params /etc/nginx/uwsgi_params
```

4. Update `nginx/nginx.conf` by using uwsgi
```bash
    location / {
          uwsgi_pass                 django-project;
          include uwsgi_params;
        }
```

5. Continue update ALLOWED_HOSTS at `django_projects/settings`
```bash
    ALLOWED_HOSTS = ['django-project', 'localhost', '127.0.0.1']
```

6. Update `all_run.sh` by running project using uwsgi
```bash
    python manage.py collectstatic && python manage.py migrate && uwsgi --socket :8000 --enable-threads --thunder-lock --ini uwsgi.ini
```

7. Build and run again project and nginx by command: `sudo docker-compose up -d --build`
8. Go to both url `localhost:80` and `localhost:8000` and check screen.
    `localhost:80` is working by connection into nginx
    `localhost:8000` is not working anymore because we are using socker, not http

