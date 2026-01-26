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

.PHONY: build
build:
	docker build \
		--pull \
		-t simulations-build \
		-f Dockerfile.build \
		.
	docker run --rm \
		-v ${working_dir}/bin:/build/bin \
		simulations-build


simulation_id ?= $(error 'simulation_id' is not set)

.PHONY: run-simulation
run-simulation:
	docker build --pull -t simulations .
	docker run --rm \
		-v ${working_dir}/output:/simulations/output \
		simulations \
		--simulation_id ${simulation_id}
