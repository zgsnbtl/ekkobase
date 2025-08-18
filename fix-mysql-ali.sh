#!/bin/bash
# 阿里云服务器MySQL启动问题一键修复脚本

echo "🚀 阿里云服务器MySQL启动问题修复"
echo "================================"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 停止所有容器
echo -e "${YELLOW}📦 停止所有容器...${NC}"
docker-compose -f docker-compose-production-simple.yml down --remove-orphans

# 2. 清理有问题的MySQL数据
echo -e "${YELLOW}🧹 清理MySQL数据卷...${NC}"
docker volume rm -f ekkobase_mysql_data 2>/dev/null || true

# 3. 清理可能的残留容器
echo -e "${YELLOW}🗑️  清理残留容器...${NC}"
docker rm -f ekkobase-mysql-1 2>/dev/null || true

# 4. 重新启动服务
echo -e "${YELLOW}🔄 重新启动服务...${NC}"
docker-compose -f docker-compose-production-simple.yml up -d

# 5. 等待MySQL初始化
echo -e "${YELLOW}⏳ 等待MySQL初始化（约30秒）...${NC}"
sleep 30

# 6. 检查状态
echo -e "${GREEN}✅ 检查服务状态：${NC}"
docker-compose -f docker-compose-production-simple.yml ps

# 7. 验证MySQL
echo -e "${GREEN}🔍 验证MySQL连接：${NC}"
docker exec ekkobase-mysql-1 mysqladmin ping 2>/dev/null && echo -e "${GREEN}MySQL运行正常${NC}" || echo -e "${RED}MySQL启动失败${NC}"

echo ""
echo -e "${GREEN}修复完成！${NC}"
echo "如果MySQL仍有问题，请检查："
echo "1. 端口3306是否被占用：netstat -tulnp | grep 3306"
echo "2. 磁盘空间是否充足：df -h"
echo "3. 内存是否足够：free -h"