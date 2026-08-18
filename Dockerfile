FROM mambaorg/micromamba:2-cuda11.7.1-ubuntu22.04 AS micromamba

FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu22.04

USER root

RUN apt-get update && apt-get install git vim jq curl -yq

ARG MAMBA_USER=foobar
ARG MAMBA_GROUP=foobar
ARG MAMBA_USER_ID=1001
ARG MAMBA_USER_GID=1001
ENV MAMBA_USER=$MAMBA_USER
ENV MAMBA_ROOT_PREFIX="/opt/conda"
ENV MAMBA_EXE="/bin/micromamba"

RUN groupadd -g $MAMBA_USER_GID $MAMBA_GROUP && \
    useradd -l -u $MAMBA_USER_ID -g $MAMBA_USER_GID $MAMBA_USER

COPY --from=micromamba "$MAMBA_EXE" "$MAMBA_EXE"
COPY --from=micromamba /usr/local/bin/_activate_current_env.sh /usr/local/bin/_activate_current_env.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_shell.sh /usr/local/bin/_dockerfile_shell.sh
COPY --from=micromamba /usr/local/bin/_entrypoint.sh /usr/local/bin/_entrypoint.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_initialize_user_accounts.sh /usr/local/bin/_dockerfile_initialize_user_accounts.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_setup_root_prefix.sh /usr/local/bin/_dockerfile_setup_root_prefix.sh

RUN /usr/local/bin/_dockerfile_initialize_user_accounts.sh && \
    /usr/local/bin/_dockerfile_setup_root_prefix.sh

# USER $MAMBA_USER

SHELL ["/usr/local/bin/_dockerfile_shell.sh"]

ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]


#
# if you need to re create env.lock, use below
# 
# COPY environment.yaml /tmp/environment.yaml
# RUN micromamba create --name default --file /tmp/environment.yaml && \
#     micromamba clean --all --yes && \
#     micromamba env export --name default --explicit > /tmp/env.lock

COPY --chown=$MAMBA_USER mamba/env.lock /tmp/env.lock 
RUN micromamba create --name default --yes --file /tmp/env.lock && \
    micromamba clean --all --yes
COPY --chown=$MAMBA_USER mamba/requirements.txt /tmp/requirements.txt
RUN micromamba run -n default pip install -r /tmp/requirements.txt


WORKDIR /opt



# USER root
# RUN mkdir -p /opt/pulmonary-tree-labeling && 
# WORKDIR /opt
# COPY --chown=$MAMBA_USER . /opt/pulmonary-tree-labeling

USER $MAMBA_USER
