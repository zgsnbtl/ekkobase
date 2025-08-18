#!/bin/bash

# MySQL 8.4 最终修复脚本
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🎯 MySQL 8.4 最终修复...${NC}"

# 1. 完全停止并清理
echo -e "${YELLOW}📦 停止并清理...${NC}"
docker-compose -f docker-compose-production-simple.yml down --volumes --remove-orphans || true
docker stop $(docker ps -q) 2>/dev/null || true

# 2. 彻底清理数据卷
echo -e "${YELLOW}🗑️ 清理数据卷...${NC}"
docker volume rm -f ekkobase_mysql_data 2>/dev/null || true
sudo rm -rf /var/lib/docker/volumes/ekkobase_mysql_data 2>/dev/null || true

# 3. 清理Docker缓存
echo -e "${YELLOW}🧹 清理Docker缓存...${NC}"
docker system prune -f --volumes || true

# 4. 重新创建数据卷
echo -e "${YELLOW}📁 重新创建数据卷...${NC}"
docker volume create ekkobase_mysql_data

# 5. 启动MySQL（使用默认配置）
echo -e "${YELLOW}🚀 启动MySQL...${NC}"
docker-compose -f docker-compose-production-simple.yml up -d mysql

# 6. 等待初始化
echo -e "${YELLOW}⏳ 等待初始化...${NC}"
sleep 30

# 7. 验证状态
echo -e "${YELLOW}🔍 验证状态...${NC}"
docker-compose -f docker-compose-production-simple.yml ps mysql

# 8. 检查连接
echo -e "${YELLOW}🔗 检查连接...${NC}"
docker-compose -f docker-compose-production-simple.yml exec mysql mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD:-nocobase} --silent && echo -e "${GREEN}✅ MySQL启动成功！${NC}" || echo -e "${RED}❌ 需要检查${NC}"

echo -e "${GREEN}🎉 修复完成！${NC}"
echo -e "${YELLOW}📋 查看日志：${NC} docker logs ekkobase-mysql-1"