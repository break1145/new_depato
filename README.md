# Depato Lease 项目 Docker 部署指南

本项目使用 Docker 容器化部署，包含前端、后端、MySQL、Redis 和 MinIO 所有服务。

## 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 4GB 可用内存
- 至少 10GB 可用磁盘空间

## 快速开始

### 1. 数据库初始化脚本

项目已包含完整的数据库初始化脚本 `depato_lease_be/lease_init.sql`，包含表结构和初始数据。

### 2. 构建并启动容器

```bash
# 构建镜像并启动所有服务
docker-compose up -d --build

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 2. 访问应用

- **前端界面**: http://localhost
- **后端API**: http://localhost:8080
- **MinIO控制台**: http://localhost:9001
  - 用户名: minioadmin
  - 密码: minioadmin

### 3. 数据库连接

- **MySQL**: localhost:3306
  - 数据库名: depato_lease
  - 用户名: root
  - 密码: (空)
- **Redis**: localhost:6379

## 服务说明

### 容器内服务

容器内运行以下服务：

1. **Nginx** (端口 80)
   - 提供前端静态文件服务
   - 代理后端API请求

2. **Spring Boot** (端口 8080)
   - 后端API服务
   - 使用本地数据库连接

3. **MySQL** (端口 3306)
   - 主数据库
   - 自动初始化数据库结构

4. **Redis** (端口 6379)
   - 缓存服务
   - 会话存储

5. **MinIO** (端口 9000/9001)
   - 对象存储服务
   - 文件上传下载

### 服务管理

使用 Supervisor 管理所有服务：

```bash
# 进入容器
docker-compose exec depato-lease-app bash

# 查看服务状态
supervisorctl status

# 重启特定服务
supervisorctl restart spring
supervisorctl restart nginx
supervisorctl restart mysql
supervisorctl restart redis
supervisorctl restart minio
```

## 数据持久化

项目使用 Docker volumes 来持久化数据：

- `mysql_data`: MySQL 数据
- `redis_data`: Redis 数据
- `minio_data`: MinIO 文件存储

## 配置说明

### 环境变量

可以在 `docker-compose.yml` 中修改以下环境变量：

- `MYSQL_ROOT_PASSWORD`: MySQL root密码
- `MYSQL_DATABASE`: 数据库名称
- `MINIO_ROOT_USER`: MinIO管理员用户名
- `MINIO_ROOT_PASSWORD`: MinIO管理员密码

### 端口映射

默认端口映射：

- 80 → 80 (前端)
- 8080 → 8080 (后端API)
- 3306 → 3306 (MySQL)
- 6379 → 6379 (Redis)
- 9000 → 9000 (MinIO API)
- 9001 → 9001 (MinIO Console)

## 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tulpn | grep :80
   
   # 修改docker-compose.yml中的端口映射
   ```

2. **内存不足**
   ```bash
   # 增加Docker内存限制
   # 或在docker-compose.yml中调整JVM参数
   ```

3. **数据库连接失败**
   ```bash
   # 检查MySQL服务状态
   docker-compose exec depato-lease-app supervisorctl status mysql
   
   # 查看MySQL日志
   docker-compose logs depato-lease-app | grep mysql
   ```

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f depato-lease-app

# 进入容器查看详细日志
docker-compose exec depato-lease-app tail -f /var/log/spring/spring.log
docker-compose exec depato-lease-app tail -f /var/log/mysql/mysql.log
```

## 停止和清理

```bash
# 停止服务
docker-compose down

# 停止服务并删除数据卷
docker-compose down -v

# 重新构建
docker-compose up -d --build --force-recreate
```

## 开发模式

如果需要开发模式，可以修改 `docker-compose.yml`：

```yaml
services:
  depato-lease-app:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      # 挂载源代码目录用于开发
      - ./depato_lease_fe:/opt/frontend
      - ./depato_lease_be:/opt/backend
```

## 生产部署建议

1. **安全性**
   - 修改默认密码
   - 使用HTTPS
   - 配置防火墙

2. **性能优化**
   - 调整JVM参数
   - 配置数据库连接池
   - 启用Redis缓存

3. **监控**
   - 配置日志收集
   - 设置健康检查
   - 监控资源使用

## 技术支持

如有问题，请查看：
- Docker 日志
- 应用日志
- 数据库日志
- 网络连接状态 
