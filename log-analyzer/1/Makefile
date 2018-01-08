NAME = openshift/log-analyzer
REGISTRY = registry.abarcloud.com

.PHONY: all build tag release

all: build

build:
	docker build -t $(NAME):latest .

tag:
	docker tag $(NAME):latest $(REGISTRY)/$(NAME):latest

release: build tag
	docker push $(REGISTRY)/$(NAME):latest
