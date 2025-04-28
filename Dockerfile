# Declare args
ARG UBUNTU_VERSION="latest"
FROM ubuntu:${UBUNTU_VERSION}

# Declare Args post FROM
ARG VELOCIRAPTOR_VERSION="latest"

LABEL version="Velociraptor"
LABEL description="Velociraptor server in a Docker container"

COPY ./entrypoint.sh .
RUN chmod +x entrypoint.sh && \
    apt-get update && \
    apt-get install -y curl wget jq rsync && \
    # Create dirs for Velo binaries
    mkdir -p /opt/velociraptor && \
    for i in linux mac windows; do mkdir -p /opt/velociraptor/$i; done && \
	# Work out the version to get
	if [ "$VELOCIRAPTOR_VERSION" != "latest" ]; then \
		VELO_URL="tags/v${VELOCIRAPTOR_VERSION}"; \
	else \
		VELO_URL="latest"; \
	fi && \
    # Get Velox binaries
    WINDOWS_EXE=$(curl -s https://api.github.com/repos/velocidex/velociraptor/releases/${VELO_URL} | jq -r '[.assets | sort_by(.created_at) | reverse | .[] | .browser_download_url | select(test("windows-amd64.exe$"))][0]')  && \
    WINDOWS_MSI=$(curl -s https://api.github.com/repos/velocidex/velociraptor/releases/${VELO_URL} | jq -r '[.assets | sort_by(.created_at) | reverse | .[] | .browser_download_url | select(test("windows-amd64.msi$"))][0]') && \
    LINUX_BIN=$(curl -s https://api.github.com/repos/velocidex/velociraptor/releases/${VELO_URL} | jq -r '[.assets | sort_by(.created_at) | reverse | .[] | .browser_download_url | select(test("linux-amd64$"))][0]') && \
    MAC_BIN=$(curl -s https://api.github.com/repos/velocidex/velociraptor/releases/${VELO_URL} | jq -r '[.assets | sort_by(.created_at) | reverse | .[] | .browser_download_url | select(test("darwin-amd64$"))][0]') && \
    wget -O /opt/velociraptor/linux/velociraptor "$LINUX_BIN" && \
    wget -O /opt/velociraptor/mac/velociraptor_client "$MAC_BIN" && \
    wget -O /opt/velociraptor/windows/velociraptor_client.exe "$WINDOWS_EXE" && \
    wget -O /opt/velociraptor/windows/velociraptor_client.msi "$WINDOWS_MSI" && \
    # Clean up 
    apt-get remove -y --purge curl wget jq && \
    apt-get autoremove -y && \
    apt-get clean
	
WORKDIR /velociraptor 
CMD ["/entrypoint.sh"]

