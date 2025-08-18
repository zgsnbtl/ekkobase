#!/bin/bash

# MySQL 容器诊断和修复脚本
set -e

echo "🔍 MySQL 容器诊断和修复"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查Docker环境
echo -e "${YELLOW}📋 检查Docker环境...${NC}"
docker --version || { echo -e "${RED}❌ Docker未安装${NC}"; exit 1; }

# 清理旧的MySQL数据
echo -e "${YELLOW}🧹 清理旧的MySQL数据...${NC}"
if [ -d "./storage/db/mysql" ]; then
    echo -e "${YELLOW}⚠️  检测到旧的MySQL数据目录${NC}"
    read -p "是否删除旧的MySQL数据？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo rm -rf ./storage/db/mysql
        echo -e "${GREEN}✅ 已清理旧的MySQL数据${NC}"
    else
        echo -e "${YELLOW}⚠️  保留现有数据，可能导致启动问题${NC}"
    fi
fi

# 创建必要的目录
echo -e "${YELLOW}📁 创建必要目录...${NC}"
mkdir -p storage/db/mysql
mkdir -p storage/logs

# 设置正确的权限
echo -e "${YELLOW}🔐 设置目录权限...${NC}"
sudo chown -R 999:999 ./storage/db/mysql  # MySQL容器用户ID
sudo chmod -R 755 ./storage/db/mysql

# 检查配置文件
echo -e "${YELLOW}📄 检查配置文件...${NC}"
if [ ! -f "mysql-production.cnf" ]; then
    echo -e "${RED}❌ mysql-production.cnf 不存在${NC}"
    exit 1
fi

# 检查环境变量
echo -e "${YELLOW}📋 检查环境变量...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env 不存在，使用 .env.production${NC}"
    cp .env.production .env
fi

# 验证环境变量
source .env
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo -e "${RED}❌ MYSQL_ROOT_PASSWORD 未设置${NC}"
    exit 1
fi

# 测试MySQL配置
echo -e "${YELLOW}🧪 测试MySQL配置...${NC}"
docker run --rm \
    --name mysql-test \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
    -e MYSQL_DATABASE=$DB_DATABASE \
    -e MYSQL_USER=$DB_USER \
    -e MYSQL_PASSWORD=$DB_PASSWORD \
    -v $(pwd)/mysql-production.cnf:/etc/mysql/conf.d/mysql-production.cnf:ro \
    -v $(pwd)/storage/db/mysql:/var/lib/mysql \
    --user 999:999 \
    mysql:8 \
    --verbose --help > /dev/null 2>&1 && echo -e "${GREEN}✅ MySQL配置验证通过${NC}" || echo -e "${RED}❌ MySQL配置验证失败${NC}"

# 启动MySQL进行测试
echo -e "${YELLOW}🚀 启动MySQL测试容器...${NC}"
docker run -d --name mysql-test \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
    -e MYSQL_DATABASE=$DB_DATABASE \
    -e MYSQL_USER=$DB_USER \
    -e MYSQL_PASSWORD=$DB_PASSWORD \
    -v $(pwd)/mysql-production.cnf:/etc/mysql/conf.d/mysql-production.cnf:ro \
    -v $(pwd)/storage/db/mysql:/var/lib/mysql \
    --user 999:999 \
    mysql:8

# 等待MySQL启动
echo -e "${YELLOW}⏳ 等待MySQL启动...${NC}"
sleep 10

# 检查容器状态
if docker ps | grep -q mysql-test; then
    echo -e "${GREEN}✅ MySQL测试容器启动成功${NC}"
    
    # 测试连接
    echo -e "${YELLOW}🔗 测试数据库连接...${NC}"
    docker exec mysql-test mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT 1;" && \
        echo -e "${GREEN}✅ 数据库连接测试通过${NC}" || \
        echo -e "${RED}❌ 数据库连接测试失败${NC}"
    
    # 停止测试容器
    docker stop mysql-test
    docker rm mysql-test
else
    echo -e "${RED}❌ MySQL测试容器启动失败${NC}"
    echo -e "${YELLOW}📋 查看日志...${NC}"
    docker logs mysql-test
    docker rm mysql-test
fi

# 最终建议
echo
echo -e "${GREEN}🎯 修复完成！建议执行：${NC}"
echo "1. ./deploy-simple.sh start"
echo "2. 或手动：docker-compose -f docker-compose-production-simple.yml up -d"
echo
echo -e "${YELLOW}💡 如果仍然失败，请检查：${NC}"
echo "- 磁盘空间：df -h"
echo "- 内存使用：free -h"
echo "- 端口占用：netstat -tulnp | grep 3306"