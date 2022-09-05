import glob
import os
import re
import sys

from binascii import a2b_hex

#from tornado.httpclient import AsyncHTTPClient
#from kubernetes import client
#from jupyterhub.utils import url_path_join

from collections import Mapping


# Make sure that modules placed in the same directory as the jupyterhub config are added to the pythonpath
configuration_directory = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, configuration_directory)
"""
from z2jh import (
    get_config,
    set_config_if_not_none,
    get_name,
    get_name_env,
    get_secret_value,
)
"""

def _merge_dictionaries(a, b):
    """Merge two dictionaries recursively.

    Simplified From https://stackoverflow.com/a/7205107
    """
    merged = a.copy()
    for key in b:
        if key in a:
            if isinstance(a[key], Mapping) and isinstance(b[key], Mapping):
                merged[key] = _merge_dictionaries(a[key], b[key])
            else:
                merged[key] = b[key]
        else:
            merged[key] = b[key]
    return merged

def set_config_if_not_none(cparent, name, key):
    """
    Find a config item of a given name, set the corresponding Jupyter
    configuration item if not None
    """
    data = get_config2(key)
    if data is not None:
        setattr(cparent, name, data)

def _load_config():
    """Load the Helm chart configuration used to render the Helm templates of
    the chart from a mounted k8s Secret, and merge in values from an optionally
    mounted secret (hub.existingSecret)."""

    cfg = {}
    for source in ("secret/values.yaml", "existing-secret/values.yaml"):
        path = f"/usr/local/etc/jupyterhub/{source}"
        if os.path.exists(path):
            print(f"Loading {path}")
            with open(path) as f:
                values = yaml.safe_load(f)
            cfg = _merge_dictionaries(cfg, values)
        else:
            print(f"No config at {path}")
    return cfg

def get_config2(key, default=None):
    """
    Find a config item of a given name & return it

    Parses everything as YAML, so lists and dicts are available too

    get_config2("a.b.c") returns config['a']['b']['c']
    """
    value = _load_config()
    # resolve path in yaml
    for level in key.split("."):
        if not isinstance(value, dict):
            # a parent is a scalar or null,
            # can't resolve full path
            return default
        if level not in value:
            return default
        else:
            value = value[level]
    return value


def camelCaseify(s):
    """convert snake_case to camelCase

    For the common case where some_value is set from someValue
    so we don't have to specify the name twice.
    """
    return re.sub(r"_([a-z])", lambda m: m.group(1).upper(), s)


c = get_config()  # noqa

c.JupyterHub.port = 9000

# dummy for testing. Don't use this in production!
c.JupyterHub.authenticator_class = "dummy"

# launch with docker
# c.JupyterHub.spawner_class = "docker"
c.JupyterHub.spawner_class = 'kubespawner.KubeSpawner'


# implement common labels
# this duplicates the jupyterhub.commonLabels helper
common_labels = c.KubeSpawner.common_labels = {}
common_labels["app"] = get_config2(
    "nameOverride",
    default=get_config2("Chart.Name", "jupyterhub"),
)
common_labels["heritage"] = "jupyterhub"
chart_name = get_config2("Chart.Name")
chart_version = get_config2("Chart.Version")
if chart_name and chart_version:
    common_labels["chart"] = "{}-{}".format(
        chart_name,
        chart_version.replace("+", "_"),
    )
release = get_config2("Release.Name")
if release:
    common_labels["release"] = release

c.KubeSpawner.namespace = os.environ.get("POD_NAMESPACE", "default")


for trait, cfg_key in (
    ("pod_name_template", None),
    ("start_timeout", None),
    ("image_pull_policy", "image.pullPolicy"),
    # ('image_pull_secrets', 'image.pullSecrets'), # Managed manually below
    ("events_enabled", "events"),
    ("extra_labels", None),
    ("extra_annotations", None),
    ("uid", None),
    ("fs_gid", None),
    ("service_account", "serviceAccountName"),
    ("storage_extra_labels", "storage.extraLabels"),
    # ("tolerations", "extraTolerations"), # Managed manually below
    ("node_selector", None),
    ("node_affinity_required", "extraNodeAffinity.required"),
    ("node_affinity_preferred", "extraNodeAffinity.preferred"),
    ("pod_affinity_required", "extraPodAffinity.required"),
    ("pod_affinity_preferred", "extraPodAffinity.preferred"),
    ("pod_anti_affinity_required", "extraPodAntiAffinity.required"),
    ("pod_anti_affinity_preferred", "extraPodAntiAffinity.preferred"),
    ("lifecycle_hooks", None),
    ("init_containers", None),
    ("extra_containers", None),
    ("mem_limit", "memory.limit"),
    ("mem_guarantee", "memory.guarantee"),
    ("cpu_limit", "cpu.limit"),
    ("cpu_guarantee", "cpu.guarantee"),
    ("extra_resource_limits", "extraResource.limits"),
    ("extra_resource_guarantees", "extraResource.guarantees"),
    ("environment", "extraEnv"),
    ("profile_list", None),
    ("extra_pod_config", None),
):
    if cfg_key is None:
        cfg_key = camelCaseify(trait)
    set_config_if_not_none(c.KubeSpawner, trait, "singleuser." + cfg_key)


# we need the hub to listen on all ips when it is in a container
#c.JupyterHub.hub_ip = '0.0.0.0'
# the hostname/ip that should be used to connect to the hub
# this is usually the hub container's name
#c.JupyterHub.hub_connect_ip = 'jupyterhub'

# pick a docker image. This should have the same version of jupyterhub
# in it as our Hub.
c.KubeSpawner.image = 'gravitydrowned/teaching-notebook:lazyjupy'

# tell the user containers to connect to our docker network
#c.DockerSpawner.network_name = 'jupyterhub'

# delete containers when the stop
#c.DockerSpawner.remove = True

c.JupyterHub.log_level = "DEBUG"
c.Spawner.debug = True