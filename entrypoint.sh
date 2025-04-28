#!/bin/bash
set -e

# Function to log messages 
log() { 
	echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

#Setup
log "Starting setup..."	

VELOX_ADDRESS="${VELO_ADDRESS:-localhost}"
BIND_ADDRESS="${BIND_ADDRESS:-0.0.0.0}" 
VELOX_FRONTEND_PUBLIC_PATH="${VELOX_FRONTEND_PUBLIC_PATH:-public}"
VELOX_FRONTEND_HOSTNAME="${VELOX_FRONTEND_HOSTNAME:-VelociraptorServer}"
VELOX_GUI_BASE_PATH="${VELOX_GUI_BASE_PATH:-/}" 
LOG_DIR="${LOG_DIR:-/logs/velociraptor}" 
DATASTORE_LOCATION="${DATASTORE_LOCATION:-./}" 
FILESTORE_DIRECTORY="${FILESTORE_DIRECTORY:-./}" 
USER_DATA="${USER_DATA:-/user_data}" 
CLIENT_DIR="${CLIENT_DIR:-/user_data/clients}"
#These are just a safetynet and are not very secure. They should be overridden by environment variables. 
VELOX_USER="${VELOX_USER:-admin}"
VELOX_PASSWORD="${VELOX_PASSWORD:-admin}"
VELOX_ROLE="${VELOX_ROLE:-administrator}"
VELOX_SERVER_URL="${VELOX_SERVER_URL:-https://VelociraptorServer:8000/}"

#Install required components
log "Installing required components..."
apt install jq -y

# Make Folders (If they dont already exist)
log "Creating necessary directories..."
mkdir -p $LOG_DIR
mkdir -p $CLIENT_DIR
mkdir -p $USER_DATA/config

# Move binaries into place
log "Moving binaries into place..."
cp /opt/velociraptor/linux/velociraptor . && chmod +x velociraptor
mkdir -p $CLIENT_DIR/linux && rsync -a /opt/velociraptor/linux/velociraptor $CLIENT_DIR/linux/velociraptor_client
mkdir -p $CLIENT_DIR/mac && rsync -a /opt/velociraptor/mac/velociraptor_client $CLIENT_DIR/mac/velociraptor_client
mkdir -p $CLIENT_DIR/windows && rsync -a /opt/velociraptor/windows/velociraptor_client* $CLIENT_DIR/windows/

# If no existing server config, set it up
log "Checking for existing server config..."
if [ ! -f server.config.yaml ]; then
	log "Server Config not found. Generating..."
	./velociraptor config generate > server.config.yaml --merge '{"Frontend":{"public_path":"'$VELOX_FRONTEND_PUBLIC_PATH'", "hostname":"'$VELOX_FRONTEND_HOSTNAME'"},"API":{"bind_address":"'$BIND_ADDRESS'"},"GUI":{"base_path":"'$VELOX_GUI_BASE_PATH'", "public_url":"https://'$VELOX_ADDRESS'/'$VELOX_GUI_BASE_PATH'/app/index.html", "bind_address":"'$BIND_ADDRESS'"},"Monitoring":{"bind_address":"'$BIND_ADDRESS'"},"Logging":{"output_directory":"'$LOG_DIR'","separate_logs_per_component":true},"Client":{"server_urls":["'$VELOX_SERVER_URL'"],"use_self_signed_ssl":true}, "Datastore":{"location":"'$DATASTORE_LOCATION'", "filestore_directory":"'$FILESTORE_DIRECTORY'"}}'
        #sed -i "s#https://localhost:8000/#$VELOX_CLIENT_URL#" server.config.yaml
	sed -i 's#/tmp/velociraptor#.#'g server.config.yaml
	./velociraptor --config server.config.yaml user add $VELOX_USER $VELOX_PASSWORD --role $VELOX_ROLE
fi

# Check Server Certificate Status, Re-generate if it's expiring in 24-hours or less
log "Checking Server Certificate Status..."
if true | ./velociraptor --config server.config.yaml config show --json | jq -r .Frontend.certificate | openssl x509 -text -enddate -noout -checkend 86400 >/dev/null; then
  log "Skipping renewal, certificate is not expired"
else
  log "Certificate is expired, rotating certificate."
  ./velociraptor --config ./server.config.yaml config rotate_keys > /tmp/server.config.yaml
  cp ./server.config.yaml ./server.config.yaml.bak
  mv /tmp/server.config.yaml /velociraptor/.
fi

# Re-generate client config in case server config changed
log "Re-generating client config..."
./velociraptor --config server.config.yaml config client > client.config.yaml

# Re-generate API config in case server config changed
log "Generating API Config based of current server config"
./velociraptor --config server.config.yaml config api_client --role administrator --name $VELOX_USER api.config.yaml 
sed -i 's/api_connection_string:.*/api_connection_string: velociraptor:8001/g' /velociraptor/api.config.yaml 

# Repack clients
log "Repacking clients..."
./velociraptor config repack --exe $CLIENT_DIR/linux/velociraptor_client client.config.yaml $CLIENT_DIR/linux/velociraptor_client_repacked
./velociraptor --config client.config.yaml debian client --output $CLIENT_DIR/linux/velociraptor_client_repacked.deb
./velociraptor --config client.config.yaml rpm client --output $CLIENT_DIR/linux/velociraptor_client_repacked.rpm
./velociraptor config repack --exe $CLIENT_DIR/mac/velociraptor_client client.config.yaml $CLIENT_DIR/mac/velociraptor_client_repacked
./velociraptor config repack --exe $CLIENT_DIR/windows/velociraptor_client.exe client.config.yaml $CLIENT_DIR/windows/velociraptor_client_repacked.exe
./velociraptor config repack --msi $CLIENT_DIR/windows/velociraptor_client.msi client.config.yaml $CLIENT_DIR/windows/velociraptor_client_repacked.msi

# Copy Config files into User Directory
log "Copying config files..."
cp *.config.yaml $USER_DATA/config/

# Set Permissions on files
log "Setting permissions..."
chmod -R a+r $CLIENT_DIR

# Start Velocoraptor
log "Starting Velociraptor..."
./velociraptor --config server.config.yaml frontend -v
