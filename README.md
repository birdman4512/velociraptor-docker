# velociraptor-docker
Run [Velocidex Velociraptor](https://github.com/Velocidex/velociraptor) server with Docker.

## Options to Run

There are two ways to run this container, via docker-compose and docker run.

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
- ```docker run --rm \
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
	velociraptor```

Make sure to update the -e, -p and --mount options 
