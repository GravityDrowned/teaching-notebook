FROM jupyter/tensorflow-notebook
# FROM jupyter/scipy-notebook # just commented out
#FROM jupyter/minimal-notebook

USER root

# Install system utilities with apt
# Also install ocaml and dependency rlwrap for L2 CS course by Kim Nguyen
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-client rsync unison less tree curl gdb imagemagick libopenjp2-7 \
        ocaml rlwrap \
        net-tools traceroute iputils-ping \
        dbus-x11 xfce4 xfce4-panel xfce4-session xfce4-settings xorg xubuntu-icon-theme && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Setup default prompt
RUN echo 'export PS1=`echo $JUPYTERHUB_USER| sed s/-at-.*//`"@jupyterhub:\w\$ "' > /etc/profile.d/02-prompt.sh
# Hack to override the setting of PS1 in the users's bashrc
RUN ln -s /etc/profile.d/02-prompt.sh /etc/bash_completion
# Enable extended file globs in bash
RUN echo 'shopt -s extglob' > /etc/profile.d/03-extglob.sh
# With the current jupyter emage, conda is activated via
# /etc/skels/.bashrc; older accounts may not beneficiate from it.
# Force activation for everyone.
RUN echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' > /etc/profile.d/04-conda-activate.sh

USER $NB_UID

# Install the base software stack
# RUN conda update  -n base -c conda-forge --update-all
COPY environment.yml .
RUN conda env update -n base -f environment.yml && rm environment.yml

# Temporarily use patched version of MethNum
# See https://gitlab.u-psud.fr/MethNum/scripts/merge_requests/4
# https://gitlab.u-psud.fr/MethNum/scripts.git

# Install the software stack for each of the following repositories
RUN for REPO in                                                \
        https://gitlab.u-psud.fr/nicolas.thiery/scripts.git    \
        https://gitlab.u-psud.fr/Info111/ComputerLab.git       \
        https://gitlab.u-psud.fr/Info122/Info122.git           \
        https://github.com/madclam/info113/                    \
        https://github.com/nthiery/M1-ISD-AlgorithmiqueAvancee \
        https://gitlab.u-psud.fr/nicolas.thiery/ter-jupyter    \
        ; do                                                   \
        echo =================================================;\
        echo Installing software stack for:                   ;\
        echo   $REPO                                          ;\
        echo =================================================;\
        git clone $REPO repo                        &&         \
        (cd repo; test -d binder && cd binder; mamba env update -n base -f environment.yml) &&         \
        rm -rf repo                                 ||         \
        break 0;                                               \
    done

## Install SageMath, for now in a different environment
#RUN mamba create --yes -n sage sage=9.1

# Enable the Visual Studio proxy extension in notebook and lab
# Taken from https://github.com/betatim/vscode-binder/blob/master/postBuild
RUN jupyter serverextension enable --py jupyter_server_proxy
RUN jupyter labextension install @jupyterlab/server-proxy
#RUN code-server --install-extension ms-python.python

# Install unpackaged jupyterlab extensions and force jupyterlab rebuild
RUN jupyter labextension install @wallneradam/run_all_buttons
