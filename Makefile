SHELL := /bin/bash
ifeq ($(shell test -e .makerc && echo -n yes),yes)
    include .makerc
else
    include .makerc.dist
endif

.PHONY: all imagestreams templates builds */ **/*.yml **/*/imagestream.yml

**/*/imagestream.yml:
	@echo "Processing and uploading imagestream in namespace $(NAMESPACE): ${@}" && \
	cat $@ \
    | sed "s|[<]NAMESPACE_HERE[>]|$(NAMESPACE)|" \
    | sed "s|[<]REPOSITORY_URL_HERE[>]|$(REPOSITORY_URL)|" \
    | sed "s|[<]REPOSITORY_REF_HERE[>]|$(REPOSITORY_REF)|" \
    | oc process -n $(NAMESPACE) -f - \
    | oc create -n $(NAMESPACE) -f - 2> /dev/null || \
	cat $@ \
    | sed "s|[<]NAMESPACE_HERE[>]|$(NAMESPACE)|" \
    | sed "s|[<]REPOSITORY_URL_HERE[>]|$(REPOSITORY_URL)|" \
    | sed "s|[<]REPOSITORY_REF_HERE[>]|$(REPOSITORY_REF)|" \
    | oc process -n $(NAMESPACE) -f - \
    | oc replace -n $(NAMESPACE) -f -

**/*.yml:
	@echo "Uploading template in namespace $(NAMESPACE): ${@}" && \
	cat $@ \
	  | sed "s|[<]NAMESPACE_HERE[>]|$(NAMESPACE)|" \
	  | sed "s|[<]REPOSITORY_URL_HERE[>]|$(REPOSITORY_URL)|" \
	  | sed "s|[<]REPOSITORY_REF_HERE[>]|$(REPOSITORY_REF)|" \
	  | oc create -n $(NAMESPACE) -f - 2> /dev/null || \
	cat $@ \
	  | sed "s|[<]NAMESPACE_HERE[>]|$(NAMESPACE)|" \
	  | sed "s|[<]REPOSITORY_URL_HERE[>]|$(REPOSITORY_URL)|" \
	  | sed "s|[<]REPOSITORY_REF_HERE[>]|$(REPOSITORY_REF)|" \
	  | oc replace -n $(NAMESPACE) -f -

imagestreams: **/*/imagestream.yml

templates: **/*.yml

*/:
	$(MAKE) $@*/imagestream.yml || true
	$(MAKE) $@*.yml

all: imagestreams templates