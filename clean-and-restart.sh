#!/bin/bash

# MySQL顽固数据问题强制清理脚本
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚨 MySQL顽固数据清理脚本...${NC}"

# 1. 完全停止Docker服务
echo -e "${YELLOW}🔴 停止Docker服务...${NC}"
sudo systemctl stop docker || true

# 2. 强制清理Docker数据
echo -e "${YELLOW}🗑️ 清理Docker数据...${NC}"
sudo rm -rf /var/lib/docker/volumes/ekkobase_mysql_data* 2>/dev/null || true
sudo rm -rf /var/lib/docker/overlay2/*/merged/var/lib/mysql 2>/dev/null || true

# 3. 清理可能的挂载点
echo -e "${YELLOW}📁 清理挂载点...${NC}"
sudo umount /var/lib/docker/volumes/ekkobase_mysql_data/_data 2>/dev/null || true
sudo rm -rf /var/lib/mysql 2>/dev/null || true

# 4. 重启Docker服务
echo -e "${YELLOW}🔄 重启Docker服务...${NC}"
sudo systemctl start docker
sleep 5

# 5. 重新部署
echo -e "${YELLOW}🚀 重新部署...${NC}"
cd /path/to/ekkobase
docker-compose -f docker-compose-production-simple.yml up -d

# 6. 等待并验证
echo -e "${YELLOW}⏳ 等待服务启动...${NC}"
sleep 60

echo -e "${YELLOW}🔍 验证状态...${NC}"
docker-compose -f docker-compose-production-simple.yml ps

echo -e "${GREEN}✅ 清理完成！${NC}"
echo -e "${YELLOW}📋 查看日志：${NC} docker-compose logs mysql"