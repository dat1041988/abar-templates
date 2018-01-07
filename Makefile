NAMESPACE=openshift
SHELL := /bin/bash

.PHONY: all imagestreams templates builds **/*.yml **/*/imagestream.yml

**/*/imagestream.yml:
	@echo "Uploading imagestream: ${@}" && \
	oc process -n $(NAMESPACE) -f $@ | oc create -f - 2> /dev/null || \
	oc process -n $(NAMESPACE) -f $@ | oc replace -f -

**/*.yml:
	@echo "Uploading template: ${@}" && \
	oc create -n $(NAMESPACE) -f $@ 2> /dev/null || oc replace -n $(NAMESPACE) -f $@

imagestreams: **/*/imagestream.yml

templates: **/*.yml

all: imagestreams templates