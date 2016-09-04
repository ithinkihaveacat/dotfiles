# README

## Getting Started

0.

Get Gandi API key and set the `GANDI_API_KEY` environment variable:

https://www.gandi.net/admin/api_key

1.

Download and install
[`docker-machine-driver-gandi`](https://github.com/Gandi/docker-machine-gandi/releases)
([more info](https://github.com/Gandi/docker-machine-gandi)).

2.

Provision Gandi virtual machine and install Docker Engine on it,
creating a "Dockerized host" that is able to run Docker containers:

```sh
$ docker-machine create \
  --driver gandi \
  --gandi-api-key=$GANDI_API_KEY \
  --gandi-image "Ubuntu 16.04 64 bits LTS (HVM)" \
  --gandi-memory 256 \
  default
```

`default` is the machine name; if this exists, then many `docker-machine`
commands will apply to this machine by default.

3.

Get `docker` command to interact with newly-created Docker Engine in
the cloud (instead of the Docker Engine provided by the local
Docker.app):

```sh
$ eval (docker-machine env default)
```

4.

(Optional.)

Test Dockerized host:

```sh
$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
c04b14da8d14: Pull complete 
Digest:
sha256:0256e8a36e2070f7bf2d0b0763dbabdd67798512411de4cdcf9431a1feb60fd9
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working
correctly.
...
```

Note: "locally" refers to where the machine is running, that is, in
the datacenter.

See Docker's [Getting Started
documentation](https://docs.docker.com/machine/get-started/#/run-containers-and-experiment-with-machine-commands)
for some more examples.

5.

Create image (named `fred`) from `~/.dotfiles/docker/Dockerfile`:

```sh
$ docker build -t fred ~/.dotfiles/docker
```

6.

Create and start a container (named `barry`):

```sh
$ docker run --privileged -it --name barry -p 80:22 -h barry -d -v /root/.ssh:/etc/ssh/keys:ro fred
```

* `--name barry` – the name of the container
* `-p 80:22` - maps port 80 on the virtual machine to port 22 on the container
* `-h barry` - the hostname of the container
* `-v /root/.ssh:/etc/ssh/keys:ro` - make contents of `/root/.ssh` on the virtual machine available (ro) as `/etc/ssh/keys` on the container
* `fred` - the name of the image 

7.

Get interactive shell (user `mjs`) on the container via `ssh`:

```sh
$ ssh -i (docker-machine inspect -f "{{.HostOptions.AuthOptions.StorePath}}")/id_rsa -p 80 mjs@(docker-machine ip)
```

Or, get interactive shell (user `root`) on the container via Docker:

```sh
$ docker exec --privileged -it barry bash -l
```

## Appendix A: Docker Concepts

`docker-machine` installs and manages Docker Engine on virtual hosts.

`docker` is the CLI to interact with Docker Engine.

A docker image is like a virtual disk.

A docker container is like a virtual machine. (A container can be
started and stopped.)

See also [What's the difference between Docker Engine and Docker
Machine?](https://docs.docker.com/machine/overview/#/what-s-the-difference-between-docker-engine-and-docker-machine)

## Appendix B: `docker` commands

Images:

* `docker images` - list images
* `docker build ...` - create image
* `docker rmi ...` - remove image
  * `docker rmi (docker images -q -a)` - remove all images

Containers:

* `docker ps -a` - list (all) containers
  * `docker ps` - list running containers
* `docker create ...` - create container
* `docker rm ...` - remove container
  * `docker rm (docker ps -q -a)` - remove all containers
* `docker start ...` - start container
* `docker stop ...` - stop container

Commands (applicable to created and started containers):

* `docker exec mycontainer echo hello` - run `echo hello` in container
  * `docker exec --privileged mycontainer echo hello` - run command in [privileged mode](https://docs.docker.com/engine/reference/run/#/runtime-privilege-and-linux-capabilities)
* `docker exec --privileged -it mycontainer bash` - start interactive shell in container
* `docker attach mycontainer` - attach to an already running container; on exit, container will stop

Commands (applicable to images):

* `docker run --privileged -it -h myhostname myimage` - create and start container, run default command and attach interactively
  * `docker run --privileged -it -h myhostname --rm myimage` - as above, but remove container on exit

## Appendix C: `docker-machine` commands

* `docker-machine ssh` - ssh into machine (not container!)
* `docker-machine ls` - list Dockerized hosts (excludes Docker.app for some reason)
* `docker-machine rm` - remove host (also (always?) destroys the virtual machine in the cloud)
