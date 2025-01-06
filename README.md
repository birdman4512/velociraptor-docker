# velociraptor-docker
Run [Velocidex Velociraptor](https://github.com/Velocidex/velociraptor) server with Docker.

## Options to Run

There are two ways to run this container, via 
- docker-compose, or
- docker run.

### Docker-compose

- Ensure [docker-compose](https://docs.docker.com/compose/install/) is installed on the host
- `git clone https://github.com/birdman4512/velociraptor-docker`
- `cd velociraptor-docker`
- Change credential values in `.env` as desired
- `docker-compose up` (or `docker-compose up -d` for detached)
- Access the Velociraptor GUI via https://\<hostip\>:8889 
  - Default u/p is `admin/admin`
  - This can be changed by running: 
  
  `docker exec -it velociraptor ./velociraptor --config server.config.yaml user add user1 user1 --role administrator`

### Docker Run

The container can be run stand alone if you wish. To do this, you build and then pass in the environment variables as part of the run command. 
- `docker build . -t velociraptor`

> [!NOTE]
> By default, the container will build using the latest versions of both Velociraptor and Ubunutu.
>
> Specific versions of both can be specified using build args. 
> For example to Velociraptor build v0.7.1 add the arguement `--build-arg VELOCIRAPTOR_VERSION=0.7.1` to the build command 
> Versions can be found at https://github.com/Velocidex/velociraptor/releases
>
> It is the same for Ubuntu Versions. 
> Example: `--build-arg UBUNTU_VERSION=24.04`
>
> Example `docker build --build-arg VELOCIRAPTOR_VERSION=0.7.1 --build-arg UBUNTU_VERSION=22.04 . -t velociraptor-0.7.1`

Start the container passing in the necessary options.
Make sure to update the -e, -p and --mount options

- ```
    docker run --rm \
	-e "VELOX_USER=admin" \
	-e "VELOX_PASSWORD=admin" \
	-e "VELOX_ROLE=administrator" \
	-e "VELOX_SERVER_URL=https://VelociraptorServer:8000/" \
	-e "VELOX_FRONTEND_HOSTNAME=VelociraptorServer" \
	-p 8889:8889 \
	-p 8000:8000 \
	-p 8899:8899 \
	--mount type=bind,source=./data,target=/velociraptor \
	--mount type=bind,source=./logs,target=/logs/velociraptor \
	--mount type=bind,source=./user_data,target=/user_data \
	velociraptor
	```

## Possible Environment variables

There are a number of environment variables that can be used to customise how the container works. They can be set in either `docker-compose` or `docker run`

- **BIND_ADDRESS** : What IP address should the service bind to. Default is `0.0.0.0`

- **FRONTEND_BASE_PATH** : Serve client frontend from this subdirectory. Default `/` 

- **GUI_BASE_PATH** : Serve GUI frontend from this subdirectory. Default `/`

- **LOG_DIR** : Directory to store log files. Default is `/logs/velociraptor}`

- **DATASTORE_LOCATION** : The directory used to store small files. Default is `./` 

- **FILESTORE_DIRECTORY** : The directory for larger result sets and uploads. Often set as the same as DATASTORE_LOCATION. Default is `./`

- **USER_DATA** : A directory to store a copy of the servers configuration files. This is here to allow you to share these files elsewhere without having to expose the running of the server. Default `/user_data`

- **CLIENT_DIR** : A directory to store a copy of the client installers. This is here to allow you to share these files elsewhere without having to expose the running of the server. Default `/user_data/clients`

- **VELOX_USER** : A username to access the server. Default `admin`

- **VELOX_PASSWORD** : A password to access the server. Default `admin`

- **VELOX_ROLE** : The roll for the account listed above. Default `administrator`

- **VELOX_SERVER_URL** : The URL of the server which is used in the client config to locate the server. Should include port. Default `https://VelociraptorServer:8000/`

- **VELOX_FRONTEND_HOSTNAME** : Publicly accessible hostname of frontend. Default `VelociraptorServer`


