# Default values for variables
REPO  ?= ubuntu-chrome-browser-use
TAG   ?= latest
VNC_PORT ?= 6080
HTTP_PORT ?= 80
WORKSPACE ?= /workspace
SHM_SIZE ?= 512m
VNC_RESOLUTION ?= 1920x1080

# Common docker run options
DOCKER_COMMON_OPTS = --privileged \
	-p $(VNC_PORT):$(HTTP_PORT) \
	-v ${PWD}:$(WORKSPACE) \
	-v /dev/shm:/dev/shm \
	-e RELATIVE_URL_ROOT=approot \
	-e VNC_RESOLUTION=$(VNC_RESOLUTION) \
	-e VNC_PASSWORD=$(VNC_PASSWORD) \
	--device /dev/snd \
	--shm-size=$(SHM_SIZE) \
	$(REPO):$(TAG)

.PHONY: build run run-test shell clean logs stop help

help:
	@echo "Available targets:"
	@echo "  build     - Build the Docker image"
	@echo "  run       - Run the container (VNC_PASSWORD=your_password make run)"
	@echo "  run-test  - Run the container in test mode (foreground, auto-remove)"
	@echo "  shell     - Open a shell in the running container"
	@echo "  logs      - Show container logs"
	@echo "  stop      - Stop the running container"
	@echo "  clean     - Remove the Docker image"

build:
	docker build --shm-size $(SHM_SIZE) -t $(REPO):$(TAG) .

# Function to prompt for VNC password if not provided
define get_vnc_password
	@if [ -z "$(VNC_PASSWORD)" ]; then \
		read -p "Enter VNC password: " pwd && \
		VNC_PASSWORD=$$pwd $(MAKE) $(1); \
	else \
		$(MAKE) $(1); \
	fi
endef

# Run the container with VNC access
run:
	$(call get_vnc_password,_run)

_run:
	docker run -d --name ubuntu-chrome-browser-use $(DOCKER_COMMON_OPTS)
	@echo "Container started in background. VNC available at localhost:$(VNC_PORT)"
	@echo "Use 'make logs' to view logs, 'make shell' to access container"

# Run container in test mode (foreground, auto-remove)
run-test:
	$(call get_vnc_password,_run-test)

_run-test:
	@echo "Running container in test mode (Ctrl+C to stop)"
	@echo "VNC will be available at localhost:$(VNC_PORT)"
	docker run --name ubuntu-chrome-browser-use-test --rm $(DOCKER_COMMON_OPTS)

# Connect inside the running container for debugging
shell:
	docker exec -it ubuntu-chrome-browser-use bash

# Show container logs
logs:
	docker logs -f ubuntu-chrome-browser-use

# Stop the running container
stop:
	@if [ -n "$(shell docker ps -q -f name=ubuntu-chrome-browser-use)" ]; then \
		echo "Stopping container..." && \
		docker stop ubuntu-chrome-browser-use; \
	else \
		echo "Container is not running"; \
	fi

# Remove the container and image
clean:
	@if [ -n "$(shell docker ps -q -f name=ubuntu-chrome-browser-use)" ]; then \
		echo "Stopping container..." && \
		docker stop ubuntu-chrome-browser-use; \
	fi
	@if docker images $(REPO):$(TAG) -q >/dev/null; then \
		echo "Removing image..." && \
		docker rmi $(REPO):$(TAG); \
	else \
		echo "Image not found"; \
	fi
	@echo "Pruning unused images..."
	docker image prune -f
