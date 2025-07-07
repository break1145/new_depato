#!/bin/bash

echo "开始构建 Depato Lease 项目..."

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查Docker Compose是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "错误: Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 停止现有容器
echo "停止现有容器..."
docker-compose down

# 清理旧镜像
echo "清理旧镜像..."
docker system prune -f

# 构建并启动
echo "构建并启动容器..."
docker-compose up -d --build

# 等待服务启动
echo "等待服务启动..."
sleep 30

# 检查服务状态
echo "检查服务状态..."
docker-compose ps

echo "构建完成！"
echo ""
echo "访问地址："
echo "- 前端界面: http://localhost"
echo "- 后端API: http://localhost:8080"
echo "- MinIO控制台: http://localhost:9001 (用户名: minioadmin, 密码: minioadmin)"
echo ""
echo "查看日志: docker-compose logs -f"
echo "停止服务: docker-compose down" 
