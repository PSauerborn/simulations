.PHONY: lint
lint:
	fprettify -r . \
		--exclude build

	black .

.PHONY: scan-secrets
scan-secrets:
	detect-secrets scan > .secrets.baseline
	detect-secrets audit .secrets.baseline

working_dir ?= $(shell pwd)

cpu_arch ?= $(shell uname -m)

# Map cpu_arch to docker platform
ifeq ($(cpu_arch),x86_64)
	platform := linux/amd64
else ifeq ($(cpu_arch),amd64)
	platform := linux/amd64
else ifeq ($(cpu_arch),aarch64)
	platform := linux/arm64
else ifeq ($(cpu_arch),arm64)
	platform := linux/arm64
else
	platform := linux/amd64
endif

.PHONY: build
build:
	docker build \
		--pull \
		--platform ${platform} \
		--build-arg CPU_ARCH=${cpu_arch} \
		-t simulations-build \
		-f Dockerfile.build \
		.
	docker run --rm \
        --platform ${platform} \
		-v ${working_dir}/bin:/build/bin \
		simulations-build


simulation_id ?= $(error 'simulation_id' is not set)

.PHONY: run-simulation
run-simulation:
	docker build --pull -t simulations -f Dockerfile.run .
	docker run --rm \
		-v ${working_dir}/output:/simulations/output \
		simulations \
		--simulation_id ${simulation_id}
