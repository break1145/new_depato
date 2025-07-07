# 使用多阶段构建
FROM node:18-alpine AS frontend-builder

# 设置工作目录
WORKDIR /app/frontend

# 复制前端依赖文件
COPY depato_lease_fe/package*.json ./

# 安装前端依赖
RUN npm ci

# 复制前端源代码
COPY depato_lease_fe/ .

# 设置生产环境变量并构建前端
RUN echo "VITE_APP_NODE_ENV='production'" > .env.production && \
    echo "VITE_APP_TITLE='后台管理'" >> .env.production && \
    echo "VITE_APP_BASE_URL='http://localhost:8081'" >> .env.production && \
    npm run build

# Java后端构建阶段
FROM maven:3.8.5-openjdk-17 as backend-build

# 设置工作目录
WORKDIR /app/backend

# 复制后端依赖文件
COPY depato_lease_be/pom.xml ./
COPY depato_lease_be/common/pom.xml ./common/
COPY depato_lease_be/model/pom.xml ./model/
COPY depato_lease_be/web/pom.xml ./web/

# 下载依赖
RUN mvn dependency:go-offline -B

# 复制后端源代码
COPY depato_lease_be/ .

# 构建后端
RUN mvn clean package -DskipTests

# 最终运行阶段
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# 安装必要的软件包
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    mysql-server \
    redis-server \
    nginx \
    supervisor \
    wget \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装MinIO
RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio \
    && chmod +x /usr/local/bin/minio

# 下载并安装MinIO客户端
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc \
    && chmod +x /usr/local/bin/mc

# 创建必要的目录
RUN mkdir -p /var/log/supervisor \
    /var/log/nginx \
    /var/log/mysql \
    /var/log/redis \
    /var/log/minio \
    /var/log/spring \
    /opt/minio/data \
    /opt/minio/config \
    /opt/spring-app \
    /opt/frontend

# 复制前端构建产物
COPY --from=frontend-builder /app/frontend/dist /opt/frontend

# 复制后端JAR文件
COPY --from=backend-builder /app/backend/web/web-admin/target/*.jar /opt/spring-app/app.jar

# 复制Docker环境的配置文件
COPY application-docker.yml /opt/spring-app/application.yml

# 复制数据库初始化脚本
COPY depato_lease_be/lease_init.sql /opt/lease_init.sql

# 配置MySQL
RUN echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';" > /opt/init_db.sql \
    && echo "FLUSH PRIVILEGES;" >> /opt/init_db.sql \
    && echo "CREATE DATABASE IF NOT EXISTS depato_lease CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" >> /opt/init_db.sql \
    && echo "USE depato_lease;" >> /opt/init_db.sql \
    && cat /opt/lease_init.sql >> /opt/init_db.sql

# 配置Nginx - 前端在81端口，代理后端8081端口
COPY <<EOF /etc/nginx/sites-available/default
server {
    listen 81;
    server_name localhost;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root /opt/frontend;
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }
    
    # 后端API代理 - 处理所有API请求，代理到8081端口
    location ~ ^/(admin|api)/ {
        proxy_pass http://localhost:8081;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # 处理跨域
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS';
        add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization,access-token';
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }
    
    # 前端静态文件 - 支持SPA路由
    location / {
        root /opt/frontend;
        try_files \$uri \$uri/ /index.html;
        index index.html;
        
        # 禁用缓存，确保前端更新生效
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
}
EOF

# 配置Supervisor
COPY <<EOF /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:mysql]
command=/usr/bin/mysqld_safe
autostart=true
autorestart=true
user=mysql
logfile=/var/log/mysql/mysql.log
log_stderr=true

[program:redis]
command=/usr/bin/redis-server /etc/redis/redis.conf
autostart=true
autorestart=true
user=redis
logfile=/var/log/redis/redis.log
log_stderr=true

[program:minio]
command=/usr/local/bin/minio server /opt/minio/data --console-address :9001
autostart=true
autorestart=true
user=root
logfile=/var/log/minio/minio.log
log_stderr=true

[program:spring]
command=java -jar /opt/spring-app/app.jar --spring.config.location=/opt/spring-app/application.yml --server.port=8081
autostart=true
autorestart=true
user=root
logfile=/var/log/spring/spring.log
log_stderr=true
environment=JAVA_OPTS="-Xmx512m -Xms256m"

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autostart=true
autorestart=true
user=root
logfile=/var/log/nginx/nginx.log
log_stderr=true
EOF

# 创建启动脚本
COPY <<EOF /opt/start.sh
#!/bin/bash

# 启动MySQL
echo "Starting MySQL..."
service mysql start

# 等待MySQL启动
sleep 15

# 初始化数据库
echo "Initializing database..."
mysql -u root < /opt/init_db.sql

# 创建MinIO bucket
echo "Creating MinIO bucket..."
sleep 5
mc alias set myminio http://localhost:9000 minioadmin minioadmin
mc mb myminio/lease --ignore-existing

# 启动所有服务
echo "Starting all services..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
EOF

RUN chmod +x /opt/start.sh

# 暴露端口：前端81，后端8081，minio 9000和9001，mysql和redis不暴露
EXPOSE 81 8081 9000 9001

# 启动命令
CMD ["/opt/start.sh"] 
