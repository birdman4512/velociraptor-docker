#!/bin/bash
set -e
BIND_ADDRESS="0.0.0.0"
PUBLIC_PATH="public"
LOG_DIR="/logs/velociraptor"
DATASTORE_LOCATION="./"
FILESTORE_DIRECTORY="./"
CLIENT_DIR="/user_data/clients"

#Install required components
apt install jq -y

# Make Folders (If they dont already exist)
mkdir -p $LOG_DIR
mkdir -p $CLIENT_DIR
mkdir -p $CLIENT_DIR/config

# Move binaries into place
cp /opt/velociraptor/linux/velociraptor . && chmod +x velociraptor
mkdir -p $CLIENT_DIR/linux && rsync -a /opt/velociraptor/linux/velociraptor $CLIENT_DIR/linux/velociraptor_client
mkdir -p $CLIENT_DIR/mac && rsync -a /opt/velociraptor/mac/velociraptor_client $CLIENT_DIR/mac/velociraptor_client
mkdir -p $CLIENT_DIR/windows && rsync -a /opt/velociraptor/windows/velociraptor_client* $CLIENT_DIR/windows/

# If no existing server config, set it up
if [ ! -f server.config.yaml ]; then
	echo "Server Config not found. Generating"
	./velociraptor config generate > server.config.yaml --merge '{"Frontend":{"public_path":"'$PUBLIC_PATH'", "hostname":"'$VELOX_FRONTEND_HOSTNAME'"},"API":{"bind_address":"'$BIND_ADDRESS'"},"GUI":{"bind_address":"'$BIND_ADDRESS'"},"Monitoring":{"bind_address":"'$BIND_ADDRESS'"},"Logging":{"output_directory":"'$LOG_DIR'","separate_logs_per_component":true},"Client":{"server_urls":["'$VELOX_SERVER_URL'"],"use_self_signed_ssl":true}, "Datastore":{"location":"'$DATASTORE_LOCATION'", "filestore_directory":"'$FILESTORE_DIRECTORY'"}}'
        #sed -i "s#https://localhost:8000/#$VELOX_CLIENT_URL#" server.config.yaml
	sed -i 's#/tmp/velociraptor#.#'g server.config.yaml
	./velociraptor --config server.config.yaml user add $VELOX_USER $VELOX_PASSWORD --role $VELOX_ROLE
fi

# Check Server Certificate Status, Re-generate if it's expiring in 24-hours or less
if true | ./velociraptor --config server.config.yaml config show --json | jq -r .Frontend.certificate | openssl x509 -text -enddate -noout -checkend 86400 >/dev/null; then
  echo "Skipping renewal, certificate is not expired"
else
  echo "Certificate is expired, rotating certificate."
  ./velociraptor --config ./server.config.yaml config rotate_keys > /tmp/server.config.yaml
  cp ./server.config.yaml ./server.config.yaml.bak
  mv /tmp/server.config.yaml /velociraptor/.
fi

# Re-generate client config in case server config changed
./velociraptor --config server.config.yaml config client > client.config.yaml

# Re-generate API config in case server config changed
echo "Generating API Config based of current server config"
./velociraptor --config server.config.yaml config api_client --role administrator --name $VELOX_USER api.config.yaml 
sed -i 's/api_connection_string:.*/api_connection_string: velociraptor:8001/g' /velociraptor/api.config.yaml 

# Repack clients
./velociraptor config repack --exe $CLIENT_DIR/linux/velociraptor_client client.config.yaml $CLIENT_DIR/linux/velociraptor_client_repacked
./velociraptor --config client.config.yaml debian client --output $CLIENT_DIR/linux/velociraptor_client_repacked.deb
./velociraptor --config client.config.yaml rpm client --output $CLIENT_DIR/linux/velociraptor_client_repacked.rpm
./velociraptor config repack --exe $CLIENT_DIR/mac/velociraptor_client client.config.yaml $CLIENT_DIR/mac/velociraptor_client_repacked
./velociraptor config repack --exe $CLIENT_DIR/windows/velociraptor_client.exe client.config.yaml $CLIENT_DIR/windows/velociraptor_client_repacked.exe
./velociraptor config repack --msi $CLIENT_DIR/windows/velociraptor_client.msi client.config.yaml $CLIENT_DIR/windows/velociraptor_client_repacked.msi

# Copy Config files into User Directory
cp *.config.yaml $CLIENT_DIR/config/

# Set Permissions on files
chmod -R a+r $CLIENT_DIR

# Start Velocoraptor
./velociraptor --config server.config.yaml frontend -v
