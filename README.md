# velociraptor-docker
Run [Velocidex Velociraptor](https://github.com/Velocidex/velociraptor) server with Docker

#### Install

- Ensure [docker-compose](https://docs.docker.com/compose/install/) is installed on the host
- `git clone https://github.com/weslambert/velociraptor-docker`
- `cd velociraptor-docker`
- Change credential values in `.env` as desired
- `docker-compose up` (or `docker-compose up -d` for detached)
- Access the Velociraptor GUI via https://\<hostip\>:8889 
  - Default u/p is `admin/admin`
  - This can be changed by running: 
  
  `docker exec -it velociraptor ./velociraptor --config server.config.yaml user add user1 user1 --role administrator`

#### Docker Run

You can run the container alone by the following

`docker build . -t velociraptor`

`docker run -e "VELOX_USER=admin" -e "VELOX_PASSWORD=admin" -e "VELOX_ROLE=administrator" -e "VELOX_SERVER_URL=https://VelociraptorServer:8000/" -e "VELOX_FRONTEND_HOSTNAME=VelociraptorServer" -p 8889:8889 -p 8000:8000 -p 8899:8899 velociraptor`
