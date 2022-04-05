FROM jupyter/tensorflow-notebook
# FROM jupyter/scipy-notebook # just commented out
#FROM jupyter/minimal-notebook

USER root

# Install system utilities with apt
## Also install ocaml and dependency rlwrap for L2 CS course by Kim Nguyen
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-client rsync unison less tree curl gdb libopenjp2-7 \
        ocaml rlwrap dune js-of-ocaml libjs-of-ocaml \
        net-tools traceroute iputils-ping \
        time \
        dbus-x11 xfce4 xfce4-panel xfce4-session xfce4-settings xorg xubuntu-icon-theme && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## Install JAVA OpenJDK-8
RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y ant && \
    apt-get clean;
    
## Fix certificate issues JAVA OpenJDK-8
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

## Setup JAVA_HOME -- useful for docker commandline
#ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
#RUN export JAVA_HOME



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
# Limit to 250M the size of files generated from commands in the shell
RUN echo 'ulimit -c 10000; ulimit -f 750000' > /etc/profile.d/05-ulimit.sh
# Force core files to be named 'core'
RUN (echo 'kernel.core_uses_pid = 0'; echo 'kernel.core_pattern = core') > /etc/sysctl.d/60-local.conf

USER $NB_UID

# Restrict jupytext to only notebook and markdown files (hacky)
RUN echo '{ "ContentsManager": {"notebook_extensions": "ipynb,md" } }' > /opt/conda/etc/jupyter/jupyter_notebook_config.json

COPY environment.yml .

# Install mamba
# Install the base software stack
# Install the software stack for each of the given repositories
# The repo for the course "Introduction à la science des données"
# is outdated and clashes with other courses (nbgrader configuration).
# Disabled:
#  https://github.com/madclam/info113/                    \
# Workaround: pip installed nbgrader-dev requires pyyaml 5.4
# but pip refuses by default to upgrade conda's pyyaml 5.3

RUN mamba env update -n base -f environment.yml             && \
    rm environment.yml                                      && \
    pip3 install --ignore-installed PyYAML                  && \
    mamba uninstall llvm-openmp -c conda-forge              && \
    for REPO in                                                \
        https://gitlab.dsi.universite-paris-saclay.fr/MethNum/scripts.git     \
        https://gitlab.dsi.universite-paris-saclay.fr/Info111/ComputerLab.git \
        https://gitlab.u-psud.fr/L1Info/IntroScienceDonnees/ComputerLab.git \
        https://gitlab.u-psud.fr/Info122/Info122.git           \
        https://gitlab.u-psud.fr/M1-ISD/AlgorithmiqueAvancee/ComputerLab \
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
    done                                                    && \
    mamba clean --all                                       && \
    pip cache purge

## Added for school ISAPP
ENV GAMMAPY_DATA=/data/2022-03-28-ISAPP/gammapy-datasets/
RUN mamba install -y -c conda-forge gammapy healpy iminuit naima emcee corner
RUN pip install sherpa
RUN pip install astroplan tsp_solver2 ligo.skymap scikit-spatial #newest


## Install SageMath, for now in a different environment
#RUN mamba create --yes -n sage sage=9.1

# Enable the Visual Studio proxy extension in notebook and lab
# Taken from https://github.com/betatim/vscode-binder/blob/master/postBuild
# RUN jupyter serverextension enable --py jupyter_server_proxy
RUN jupyter labextension install @jupyterlab/server-proxy
RUN code-server --install-extension ms-python.python
RUN pip install git+https://github.com/betatim/vscode-binder.git

# Install pytorch for cpu (conda install fails for now)
RUN pip install torch==1.9.1+cpu torchvision==0.10.1+cpu torchaudio==0.9.1 -f https://download.pytorch.org/whl/torch_stable.html
#RUN pip install git+https://gitlab.inria.fr/dchen/CKN-seq.git 


# Install unpackaged jupyterlab extensions
# run_all_buttons is currently incompatible with latest JupyterLab 3;
# ignoring error message for now
RUN jupyter labextension install @wallneradam/run_all_buttons; exit 0

# # Force jupyterlab rebuild (see https://github.com/jupyterlab/jupyterlab/issues/4930)
# RUN jupyter lab build && \
#     jupyter lab clean && \
#     jlpm cache clean && \
#     npm cache clean --force

# Force nbgrader extension reinstallation to ensure 0.7.dev
# Install Min's editor-tabs extension to enable tabs in the jupyter editor
RUN jupyter nbextension install --sys-prefix --py nbgrader --overwrite && \
    jupyter nbextension enable --sys-prefix --py nbgrader && \
    jupyter serverextension enable --sys-prefix --py nbgrader && \
    jupyter nbextension install --sys-prefix https://raw.githubusercontent.com/minrk/ipython_extensions/master/nbextensions/editor-tabs.js && \
    jupyter nbextension enable --section edit editor-tabs && \
    jupyter lab clean && \
    jlpm cache clean && \
    npm cache clean --force && \
    exit 0

# pip cache purge && \
