# 使用 Alpine 作为基础镜像，轻量级
FROM alpine:latest

# 更新包列表并安装必要的软件
# - nodejs 和 npm 用于运行 JavaScript
# - python3 和 py3-pip 用于运行 Python
# - busybox 提供 crontab 和 crond 支持（Alpine 默认使用 BusyBox 的 cron）
RUN apk update && \
    apk add --no-cache \
        nodejs \
        npm \
        python3 \
        py3-pip \
        busybox && \
    # 确保 crontab 命令可用（BusyBox 提供）
    ln -sf /bin/busybox /usr/bin/crontab && \
    # 创建 cron 日志目录
    mkdir -p /var/spool/cron/crontabs && \
    # 清理缓存以减小镜像大小
    rm -rf /var/cache/apk/*
# 设置工作目录（可选，根据需要调整）
WORKDIR /app    
# 复制一个启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# 创建 cron 必需目录和日志文件
RUN mkdir -p /var/spool/cron/crontabs /var/log && \
    touch /var/log/cron.log && \
    chmod 666 /var/log/cron.log
# 写入 crontab（每2分钟执行一次）
RUN echo "# */2 * * * * date >> /var/log/cron.log 2>&1" > /var/spool/cron/crontabs/root
# 示例：复制你的代码到容器中（在 GitHub Actions 中你可以构建时复制）
# 这一步最关键！！！权限必须是 600 + root:root
RUN chmod 600 /var/spool/cron/crontabs/root && \
    chown root:root /var/spool/cron/crontabs/root
COPY crontab /app/crontab
# 默认命令：启动 crond 并保持容器运行（你可以根据需要修改为运行特定脚本）
# 注意：crond 需要在前台运行以保持容器活跃，通常结合 tail -f /dev/null 或其他方式
ENTRYPOINT ["/entrypoint.sh"]
CMD ["crond", "-f", "-l", "4"]
