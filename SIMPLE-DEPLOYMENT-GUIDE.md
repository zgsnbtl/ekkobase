# NocoBase 简洁版生产环境部署指南

## 🎯 快速开始（无Nginx版）

### 1. 一键部署（推荐）
```bash
# 1. 使脚本可执行
chmod +x deploy-simple.sh

# 2. 初始化并启动
./deploy-simple.sh start
```

### 2. 手动部署
```bash
# 创建必要目录
mkdir -p storage/{db/mysql,redis,logs,uploads}

# 启动服务
docker-compose -f docker-compose-production-simple.yml up -d
```

## 📋 部署配置说明

### 服务架构
- **NocoBase**: 直接运行在13000端口
- **MySQL**: 8.0版本，优化配置
- **Redis**: 7-alpine版本，内存优化
- **无Nginx**: 直接使用NocoBase内置服务

### 端口配置
- **13000**: NocoBase应用端口
- **3306**: MySQL数据库端口（内部使用）
- **6379**: Redis端口（内部使用）

## 🔧 部署步骤

### 步骤1: 环境准备
```bash
# 检查Docker
./deploy-simple.sh init

# 或直接创建目录
mkdir -p storage/{db/mysql,redis,logs,uploads}
```

### 步骤2: 修改配置（可选）
编辑 `.env.production` 文件：
```bash
# 应用密钥（重要！请修改）
APP_KEY=your-very-secure-key-here

# 数据库密码（重要！请修改）
DB_PASSWORD=your-secure-password
MYSQL_ROOT_PASSWORD=your-root-password
```

### 步骤3: 启动服务
```bash
# 使用脚本
./deploy-simple.sh start

# 或直接启动
docker-compose -f docker-compose-production-simple.yml up -d
```

### 步骤4: 验证部署
```bash
# 检查服务状态
./deploy-simple.sh status

# 测试访问
curl -I http://localhost:13000

# 浏览器访问
http://localhost:13000
```

## 📊 常用命令

### 服务管理
```bash
# 启动服务
./deploy-simple.sh start

# 停止服务
./deploy-simple.sh stop

# 重启服务
./deploy-simple.sh restart

# 查看日志
./deploy-simple.sh logs

# 查看状态
./deploy-simple.sh status

# 更新镜像
./deploy-simple.sh update
```

### Docker命令
```bash
# 查看容器状态
docker-compose -f docker-compose-production-simple.yml ps

# 查看实时日志
docker-compose -f docker-compose-production-simple.yml logs -f

# 停止所有服务
docker-compose -f docker-compose-production-simple.yml down
```

## 🔍 故障排除

### 常见问题

#### 1. 端口13000被占用
```bash
# 查看占用进程
lsof -i:13000

# 修改端口（编辑docker-compose-production-simple.yml）
ports:
  - '8080:80'  # 改为8080或其他端口
```

#### 2. 容器无法启动
```bash
# 查看详细日志
docker-compose -f docker-compose-production-simple.yml logs

# 检查配置
docker-compose -f docker-compose-production-simple.yml config
```

#### 3. 数据库连接失败
```bash
# 检查MySQL状态
docker-compose -f docker-compose-production-simple.yml logs mysql

# 检查网络
docker network ls
```

#### 4. 内存不足
```bash
# 查看资源使用
./deploy-simple.sh status

# 调整内存限制
# 编辑 docker-compose-production-simple.yml
# 修改 deploy.resources.limits.memory
```

## 🗂️ 目录结构

```
./
├── storage/
│   ├── db/mysql/     # MySQL数据
│   ├── redis/        # Redis数据
│   ├── logs/         # 应用日志
│   └── uploads/      # 上传文件
├── .env.production   # 环境变量配置
├── docker-compose-production-simple.yml  # Docker配置
└── deploy-simple.sh  # 部署脚本
```

## 🌐 访问方式

### 本地访问
- **Web界面**: http://localhost:13000
- **API测试**: http://localhost:13000/api/health

### 远程访问
```bash
# 开放防火墙端口（Linux）
sudo ufw allow 13000

# 阿里云安全组
# 添加安全组规则：端口13000，协议TCP
```

### 域名配置（可选）
如果需要使用域名，可以在DNS解析中指向服务器IP，然后访问：
- http://your-domain.com:13000

## 📈 性能监控

### 资源监控
```bash
# 查看容器资源使用
docker stats

# 查看磁盘使用
df -h

# 查看内存使用
free -h
```

### 日志查看
```bash
# 应用日志
docker-compose -f docker-compose-production-simple.yml logs app

# 数据库日志
docker-compose -f docker-compose-production-simple.yml logs mysql

# Redis日志
docker-compose -f docker-compose-production-simple.yml logs redis
```

## 🔄 数据备份

### 手动备份
```bash
# 备份数据库
docker-compose -f docker-compose-production-simple.yml exec mysql \
  mysqldump -u root -p nocobase > backup-$(date +%Y%m%d).sql

# 备份上传文件
cp -r storage/uploads backup-uploads-$(date +%Y%m%d)/
```

### 自动备份（推荐）
```bash
# 添加定时任务
crontab -e

# 每天凌晨2点备份
0 2 * * * docker-compose -f /path/to/docker-compose-production-simple.yml exec mysql mysqldump -u root -pYOUR_PASSWORD nocobase > /backup/nocobase-$(date +\%Y\%m\%d).sql
```

## 🚀 升级指南

### 镜像更新
```bash
# 使用脚本更新
./deploy-simple.sh update

# 手动更新
docker-compose -f docker-compose-production-simple.yml pull
docker-compose -f docker-compose-production-simple.yml up -d
```

### 版本回滚
```bash
# 停止当前服务
docker-compose -f docker-compose-production-simple.yml down

# 回滚到特定版本
# 修改docker-compose-production-simple.yml中的image版本
docker-compose -f docker-compose-production-simple.yml up -d
```

## 📞 技术支持

### 官方资源
- **文档**: https://docs.nocobase.com
- **GitHub**: https://github.com/nocobase/nocobase
- **社区**: https://github.com/nocobase/nocobase/discussions

### 日志位置
- **应用日志**: ./storage/logs/
- **数据库日志**: ./storage/logs/mysql/
- **Redis日志**: ./storage/logs/redis/