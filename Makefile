IAMLIVE_VERSION     := v0.42.0
IAMLIVE_DOCKER_IMG  := iamlive-run
DOCKER_NETWORK_NAME := my-net

all: iamlive-proxy sam iamlive-output

init:
	pip install -r scripts/requirements.txt
	docker network ls | grep $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(DOCKER_NETWORK_NAME)
	$(MAKE) build-iamlive

env-vars.json:
	./scripts/generate.py -a env-vars -o $@

template-gen.yaml:
	./scripts/generate.py -a template -o $@

build-iamlive:
	curl -fsSL https://github.com/iann0036/iamlive/releases/download/$(IAMLIVE_VERSION)/iamlive-$(IAMLIVE_VERSION)-linux-amd64.tar.gz -o iamlive/iamlive-$(IAMLIVE_VERSION)-linux-amd64.tar.gz
	tar -C iamlive/ -zxf iamlive/iamlive-$(IAMLIVE_VERSION)-linux-amd64.tar.gz
	rm -f iamlive/iamlive-$(IAMLIVE_VERSION)-linux-amd64.tar.gz
	docker build -t $(IAMLIVE_DOCKER_IMG) iamlive/

iamlive-proxy:
	docker run --network $(DOCKER_NETWORK_NAME) \
		--rm -d --name iamlive \
		-v "${PWD}:/iamlive" \
		$(IAMLIVE_DOCKER_IMG) \
		--mode proxy --bind-addr 0.0.0.0:10080 \
		--ca-bundle /iamlive/ca.pem \
		--output-file /iamlive/iamlive.log
	@echo "Waiting for ca.pem "
	@while [[ ! -f ca.pem ]]; do sleep 1; done; echo "Done!"

iamlive-output:
	docker exec iamlive kill -HUP 1
	cat iamlive.log

sam: env-vars.json template-gen.yaml
	# TODO: Implement support for multiple functions here
	# TODO: Check if both --container-env-vars and --env vars are required, or just one of them
	cp ca.pem hello_world/ca.pem
	sam local invoke HelloWorldFunction \
		--container-env-vars env-vars.json \
		--env-vars env-vars.json \
		--template-file template-gen.yaml \
		--docker-network $(DOCKER_NETWORK_NAME)

clean:
	docker kill iamlive 2>/dev/null || true
	find . -type f -name ca.pem -delete
	rm -f iamlive.log env-vars.json template-gen.yaml

purge: clean
	docker network rm $(DOCKER_NETWORK_NAME)
	docker rmi $(IAMLIVE_DOCKER_IMG)

