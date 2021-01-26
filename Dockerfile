FROM jupyter/tensorflow-notebook
# FROM jupyter/scipy-notebook # just commented out
#FROM jupyter/minimal-notebook

USER root

# Install system utilities with apt
# Also install ocaml and dependency rlwrap for L2 CS course by Kim Nguyen
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-client rsync unison less tree curl gdb imagemagick libopenjp2-7 \
        ocaml rlwrap dune js-of-ocaml libjs-of-ocaml \
        net-tools traceroute iputils-ping \
        time \
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
# Limit to 10M the size of core dumps
# Limit to 100M the size of files generated from commands in the shell
RUN echo 'ulimit -c 10000; ulimit -f 100000' > /etc/profile.d/05-ulimit.sh
RUN echo 'ulimit -c 10000; ulimit -f 100000' > /etc/profile.d/05-ulimit.sh
# Force core files to be named 'core'
RUN echo 'kernel.core_uses_pid = 0' > /etc/sysctl.d/60-local.conf

USER $NB_UID

# Install mamba
RUN conda install mamba -c conda-forge

# Install the base software stack
# RUN conda update  -n base -c conda-forge --update-all
COPY environment.yml .
RUN mamba env update -n base -f environment.yml && rm environment.yml

# Workaround: pip installed nbgrader-dev requires pyyaml 5.4
# but pip refuses by default to upgrade conda's pyyaml 5.3
RUN pip3 install --ignore-installed PyYAML

# The repo for the course "Introduction à la science des données"
# is outdated and clashes with other courses (nbgrader configuration).
# Disabled
#  https://github.com/madclam/info113/                    \

# Install the software stack for each of the following repositories
RUN for REPO in                                                \
        https://gitlab.u-psud.fr/MethNum/scripts.git           \
        https://gitlab.u-psud.fr/Info111/ComputerLab.git       \
        https://gitlab.u-psud.fr/Info122/Info122.git           \
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

# Install unpackaged jupyterlab extensions
RUN jupyter labextension install @wallneradam/run_all_buttons

# # Force jupyterlab rebuild (see https://github.com/jupyterlab/jupyterlab/issues/4930)
# RUN jupyter lab build && \
#     jupyter lab clean && \
#     jlpm cache clean && \
#     npm cache clean --force

# Force nbgrader extension reinstallation to ensure 0.7.dev
RUN jupyter nbextension install --sys-prefix --py nbgrader --overwrite && \
    jupyter nbextension enable --sys-prefix --py nbgrader && \
    jupyter serverextension enable --sys-prefix --py nbgrader && \
    jupyter lab clean && \
    jlpm cache clean && \
    npm cache clean --force && \
    pip cache prune
