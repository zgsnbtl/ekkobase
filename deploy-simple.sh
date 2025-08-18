#!/bin/bash

# NocoBase 简洁版生产环境部署脚本
# 无Nginx配置，直接使用NocoBase内置服务

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="docker-compose-production-simple.yml"
ENV_FILE=".env.production"

# 帮助信息
show_help() {
    echo -e "${BLUE}NocoBase 简洁版生产环境部署${NC}"
    echo ""
    echo "使用方法:"
    echo "  $0 [命令]"
    echo ""
    echo "命令:"
    echo "  init     初始化部署环境"
    echo "  start    启动服务"
    echo "  stop     停止服务"
    echo "  restart  重启服务"
    echo "  update   更新镜像"
    echo "  logs     查看日志"
    echo "  status   查看状态"
    echo "  help     显示帮助"
}

# 检查依赖
check_dependencies() {
    echo -e "${YELLOW}检查系统环境...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: Docker 未安装${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}错误: Docker Compose 未安装${NC}"
        exit 1
    fi
}

# 创建配置文件
create_config() {
    if [[ ! -f "$ENV_FILE" ]]; then
        echo -e "${YELLOW}创建配置文件...${NC}"
        cat > "$ENV_FILE" << EOF
# NocoBase 生产环境配置

# 应用密钥（请修改为随机字符串）
APP_KEY=your-secret-key-here

# 数据库配置
DB_DIALECT=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=nocobase
DB_USER=nocobase
DB_PASSWORD=nocobase_secure_password

# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379

# 时区
TZ=Asia/Shanghai
NODE_ENV=production
EOF
        echo -e "${GREEN}✅ 配置文件已创建: $ENV_FILE${NC}"
    fi
}

# 初始化环境
init() {
    echo -e "${BLUE}初始化部署环境...${NC}"
    
    # 创建必要目录
    mkdir -p storage/{db/mysql,redis,logs,uploads}
    
    # 设置权限
    chmod -R 755 storage
    
    # 检查并创建环境变量文件
    if [[ ! -f .env ]]; then
        if [[ -f "$ENV_FILE" ]]; then
            echo -e "${YELLOW}复制环境变量配置...${NC}"
            cp "$ENV_FILE" .env
            echo -e "${YELLOW}⚠️  请编辑 .env 文件，修改默认的密码和密钥！${NC}"
        else
            echo -e "${RED}❌ 未找到 $ENV_FILE 文件${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ 环境变量文件已存在${NC}"
    fi
    
    # 检查配置文件
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        echo -e "${RED}错误: 找不到 $COMPOSE_FILE${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 目录和配置创建完成${NC}"
}

# 启动服务
start() {
    echo -e "${BLUE}启动 NocoBase 服务...${NC}"
    
    # 检查端口
    if lsof -i:13000 &> /dev/null; then
        echo -e "${RED}错误: 端口 13000 已被占用${NC}"
        exit 1
    fi
    
    # 启动服务
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # 等待启动
    echo -e "${YELLOW}等待服务启动...${NC}"
    sleep 30
    
    # 检查状态
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        echo -e "${GREEN}✅ 服务启动成功${NC}"
        echo "访问地址: http://localhost:13000"
        status
    else
        echo -e "${RED}❌ 服务启动失败${NC}"
        logs
    fi
}

# 停止服务
stop() {
    echo -e "${BLUE}停止服务...${NC}"
    docker-compose -f "$COMPOSE_FILE" down
    echo -e "${GREEN}✅ 服务已停止${NC}"
}

# 重启服务
restart() {
    echo -e "${BLUE}重启服务...${NC}"
    docker-compose -f "$COMPOSE_FILE" restart
    echo -e "${GREEN}✅ 服务已重启${NC}"
}

# 更新镜像
update() {
    echo -e "${BLUE}更新镜像...${NC}"
    docker-compose -f "$COMPOSE_FILE" pull
    docker-compose -f "$COMPOSE_FILE" up -d
    echo -e "${GREEN}✅ 镜像更新完成${NC}"
}

# 查看日志
logs() {
    echo -e "${BLUE}服务日志:${NC}"
    docker-compose -f "$COMPOSE_FILE" logs -f --tail=50
}

# 查看状态
status() {
    echo -e "${BLUE}服务状态:${NC}"
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo -e "${BLUE}资源使用:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

# 主程序
main() {
    case "${1:-help}" in
        init)
            check_dependencies
            init
            ;;
        start)
            check_dependencies
            init
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        update)
            update
            ;;
        logs)
            logs
            ;;
        status)
            status
            ;;
        help)
            show_help
            ;;
        *)
            echo -e "${RED}未知命令: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 执行
main "$@"