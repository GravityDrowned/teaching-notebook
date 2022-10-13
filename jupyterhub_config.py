c = get_config()  # noqa

c.JupyterHub.port = 8000

# dummy for testing. Don't use this in production!
# c.JupyterHub.authenticator_class = "dummy"

# https://oauthenticator.readthedocs.io/en/latest/getting-started.html#gitlab-setup
# ToDo:  LocalGitLabOAuthenticator ?
# Configuration file for jupyterhub.

# /etc/jupyterhub/jupyterhub_config.py

# used to read the json gitlab oauth config file
import json

from oauthenticator.gitlab import LocalGitLabOAuthenticator

# PAM Authenticator

c = get_config()
c.JupyterHub.log_level = 10
c.Spawner.cmd = '/srv/jupyterhub/venv/bin/jupyterhub-singleuser'
c.Spawner.default_url = '/lab'

# Cookie Secret Files
c.JupyterHub.cookie_secret_file = '/srv/jupyterhub/jupyterhub_cookie_secret'
c.ConfigurableHTTPProxy.auth_token = '/srv/jupyterhub/proxy_auth_token'

# Users
# c.Authenticator.whitelist = {'ritter'}
# c.Authenticator.admin_users = {'ritter'}

# sets a custom html template at the login screen.
c.JupyterHub.template_paths = ['/srv/jupyterhub/custom-templates/']

c.JupyterHub.authenticator_class = LocalGitLabOAuthenticator

with open('./gitlab_oauth_credentials.json') as f:
    gitlab_oauth = json.load(f)

c.LocalGitLabOAuthenticator.client_id = gitlab_oauth['web']['application_id']
c.LocalGitLabOAuthenticator.client_secret = gitlab_oauth['web']['secret']

c.LocalGitLabOAuthenticator.oauth_callback_url = 'http://[2a02:810d:903f:e44c:d8bb:b132:7df9:3771]:8000/hub/oauth_callback' # replace with your domain
c.LocalGitLabOAuthenticator.create_system_users = True
c.Authenticator.add_user_cmd = ['adduser', '-q', '--gecos', '""', '--disabled-password', '--force-badname']
c.LocalGitLabOAuthenticator.hosted_domain = ''   # replace with your domain
c.LocalGitLabOAuthenticator.login_service = 'MICHI'  # replace with your 'College Name'

# Users
#c.Authenticator.whitelist = {'ritter','viviana'}
c.Authenticator.admin_users = {'wagner','michael.wagner'}




# User containers will access hub by container name on the Docker network
c.JupyterHub.hub_ip = 'jupyterhub'
c.JupyterHub.hub_port = 8000








# launch with docker
c.JupyterHub.spawner_class = "docker"

# we need the hub to listen on all ips when it is in a container
c.JupyterHub.hub_ip = '0.0.0.0'
# the hostname/ip that should be used to connect to the hub
# this is usually the hub container's name
c.JupyterHub.hub_connect_ip = 'jupyterhub'

# pick a docker image. This should have the same version of jupyterhub
# in it as our Hub.
c.DockerSpawner.image = 'gravitydrowned/teaching-notebook:lazyjupy'

# tell the user containers to connect to our docker network
c.DockerSpawner.network_name = 'bridge'

# delete containers when the stop
c.DockerSpawner.remove = True