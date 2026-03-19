#!/bin/bash

# Build the Docker image if it doesn't exist
docker build -t patchkit/tools -f docker/running/Dockerfile .

# Run the test inside the container
docker run --network="host" -it --rm \
  -v $(pwd):/workdir \
  -v /tmp:/host_tmp \
  patchkit/tools \
  bash -c "BUNDLE_WITHOUT=development bundle exec ruby $@" 