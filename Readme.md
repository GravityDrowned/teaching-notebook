HowTo: run this
```
docker network create jupyterhub
docker pull gravitydrowned/teaching-notebook:lazyjupy
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock --net jupyterhub --name jupyterhub -p8000:8000 gravitydrowned/teaching-notebook:docker
```
Following [this](https://github.com/jupyterhub/dockerspawner/tree/main/examples/simple) tutorial, this is what you need to start a JupyterHub via Docker. 
It has dummy authentication and lazyjupy as the default notebook.


Repo containing the Docker image: https://hub.docker.com/repository/docker/gravitydrowned/teaching-notebook
