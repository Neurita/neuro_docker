.PHONY: help build tag

version-var := "__version__ = "
version-string := $(shell grep $(version-var) version.py)
version := $(subst __version__ = ,,$(version-string))

help:
	@echo "build - build the container with the given name."
	@echo "tag - create a git tag with current version."

build:
	@read -p "Enter container name:" container; \
	docker build -t=$$container .

login:
	@read -p "Enter container name:" container; \
	docker build -t=$$container .

tag:
	@echo "Creating git tag v$(version)"
	git tag v$(version)
	git push --tags
