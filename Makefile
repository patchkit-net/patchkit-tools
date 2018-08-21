IMAGE=patchkit/tools-builder

build:
	docker build -t $(IMAGE) -f building/Dockerfile .

	docker run -it --rm -v $(PWD):/workdir $(IMAGE) rake package
	@each All done! You may find zip files in packaging/output directory