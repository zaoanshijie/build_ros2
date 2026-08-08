ARG ROS2_VERSION=jazzy
ARG BASE_IMAGE=ubuntu:24.04
ARG DEP_ONLY=false

FROM ${BASE_IMAGE}

ARG ROS2_VERSION
ARG DEP_ONLY

# 将脚本复制进镜像
COPY build_docker_env.sh /tmp/build.sh

# 单个 RUN 执行脚本（所有操作都在这一层完成）
RUN chmod +x /tmp/build.sh && \
    /tmp/build.sh -r ${ROS2_VERSION} -d ${DEP_ONLY} && \
    rm -rf /tmp/*

ENTRYPOINT ["/bin/bash", "-c"]
