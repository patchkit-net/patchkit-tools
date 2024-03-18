BUILDER_IMAGE=patchkit/tools-builder
RUNNER_IMAGE=patchkit/tools

build:
	sudo rm -f packaging/output/*.zip
	
	docker build -t $(BUILDER_IMAGE) -f docker/building/Dockerfile .
	docker run -it --rm -v $(PWD):/workdir $(BUILDER_IMAGE) bundle install
	docker run -it --rm -v $(PWD):/workdir $(BUILDER_IMAGE) rake -v package
	@echo All done! You may find zip files in packaging/output directory

bash:
	docker build -t $(RUNNER_IMAGE) -f docker/running/Dockerfile .
	docker run -it --rm -v $(PWD):/workdir $(RUNNER_IMAGE) bash