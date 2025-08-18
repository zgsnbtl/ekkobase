#!/bin/bash

# 阿里云服务器MySQL修复脚本
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 开始修复阿里云MySQL容器问题...${NC}"

# 1. 停止并清理现有容器
echo -e "${YELLOW}📦 停止现有容器...${NC}"
docker-compose -f docker-compose-production-simple.yml down --volumes --remove-orphans || true

# 2. 强制删除问题数据卷
echo -e "${YELLOW}🗑️ 清理问题数据卷...${NC}"
docker volume rm -f ekkobase_mysql_data 2>/dev/null || true
docker volume rm -f $(docker volume ls -q | grep mysql) 2>/dev/null || true

# 3. 清理Docker缓存
echo -e "${YELLOW}🧹 清理Docker缓存...${NC}"
docker system prune -f --volumes || true

# 4. 确保目录权限
echo -e "${YELLOW}🔐 设置目录权限...${NC}"
sudo rm -rf /var/lib/docker/volumes/ekkobase_mysql_data 2>/dev/null || true
sudo mkdir -p /var/lib/docker/volumes/ekkobase_mysql_data/_data 2>/dev/null || true

# 5. 重新启动服务
echo -e "${YELLOW}🚀 重新启动MySQL容器...${NC}"
docker-compose -f docker-compose-production-simple.yml up -d mysql

# 6. 等待MySQL启动
echo -e "${YELLOW}⏳ 等待MySQL启动...${NC}"
sleep 30

# 7. 检查状态
echo -e "${YELLOW}🔍 检查容器状态...${NC}"
docker-compose -f docker-compose-production-simple.yml ps mysql

# 8. 验证连接
echo -e "${YELLOW}🔗 验证MySQL连接...${NC}"
docker-compose -f docker-compose-production-simple.yml exec mysql mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD:-nocobase} --silent && echo -e "${GREEN}✅ MySQL连接成功！${NC}" || echo -e "${RED}❌ MySQL连接失败，请检查日志${NC}"

echo -e "${GREEN}🎉 修复完成！${NC}"
echo -e "${YELLOW}📋 查看日志命令：${NC}"
echo "docker logs ekkobase-mysql-1"
echo "docker-compose -f docker-compose-production-simple.yml logs mysql"