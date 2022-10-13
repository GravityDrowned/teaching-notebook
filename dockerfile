FROM jupyterhub/jupyterhub
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --no-cache -r /tmp/requirements.txt

COPY gitlab_oauth_credentials.json .
COPY jupyterhub_config.py .