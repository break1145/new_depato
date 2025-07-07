# Depato Lease Docker 部署指南

## 项目概述

这是一个包含前端、后端、数据库的完整租赁管理系统，所有服务运行在同一个Docker容器中。

## 服务端口配置

- **前端**: 81端口 (Nginx)
- **后端**: 8081端口 (Spring Boot)
- **MinIO API**: 9000端口
- **MinIO Console**: 9001端口
- **MySQL**: 3306端口 (仅容器内部访问)
- **Redis**: 6379端口 (仅容器内部访问)

## 快速启动
### 使用脚本
```bash
chmod +x build.sh
./build.sh
```
### 使用 Docker Compose (推荐)

```bash
# 构建并启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 使用 Docker 命令

```bash
# 构建镜像
docker build -t depato-lease .

# 运行容器
docker run -d \
  --name depato-lease-app \
  -p 81:81 \
  -p 8081:8081 \
  -p 9000:9000 \
  -p 9001:9001 \
  depato-lease
```

## 访问地址

- **前端管理界面**: http://localhost:81
- **后端API**: http://localhost:8081
- **MinIO Console**: http://localhost:9001
  - 用户名: minioadmin
  - 密码: minioadmin

## 数据库配置

- **数据库名**: depato_lease
- **用户名**: root
- **密码**: (空)
- **端口**: 3306 (仅容器内部)

数据库会在容器启动时自动初始化，运行 `lease_init.sql` 脚本。

## 服务管理

容器内使用 Supervisor 管理所有服务：

- MySQL
- Redis
- MinIO
- Spring Boot 应用
- Nginx

## 日志查看

```bash
# 查看所有服务日志
docker logs depato-lease-app

# 查看特定服务日志
docker exec depato-lease-app tail -f /var/log/spring/spring.log
docker exec depato-lease-app tail -f /var/log/nginx/nginx.log
docker exec depato-lease-app tail -f /var/log/mysql/mysql.log
```

## 故障排除

### 1. 端口冲突
如果端口被占用，可以修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "8082:81"      # 前端使用8082端口
  - "8083:8081"    # 后端使用8083端口
```

### 2. 数据库连接问题
确保容器完全启动后再访问应用，数据库初始化需要一些时间。

### 3. 前端无法访问后端
检查nginx配置是否正确代理到8081端口，确保后端服务正常运行。

## 开发模式

如果需要开发模式，可以分别启动各个服务：

```bash
# 启动数据库
docker run -d --name mysql -p 3306:3306 mysql:8.0

# 启动Redis
docker run -d --name redis -p 6379:6379 redis:7-alpine

# 启动MinIO
docker run -d --name minio -p 9000:9000 -p 9001:9001 minio/minio server /data --console-address :9001
```

## 注意事项

1. 首次启动需要较长时间，因为需要下载依赖和初始化数据库
2. 所有数据存储在Docker volumes中，容器删除后数据会丢失
3. 生产环境建议使用外部数据库和Redis
4. 确保服务器有足够的内存和磁盘空间 
