FROM ubuntu:24.04

# 将脚本复制进镜像
COPY build_docker_env.sh /tmp/build.sh

# 单个 RUN 执行脚本（所有操作都在这一层完成）
RUN chmod +x /tmp/build.sh && \
    /tmp/build.sh && \
    rm -rf /tmp/*

ENTRYPOINT ["/bin/bash", "-c"]
