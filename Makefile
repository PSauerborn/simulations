.PHONY: lint
lint:
	fprettify -r . \
		--exclude build

	black .

.PHONY: scan-secrets
scan-secrets:
	detect-secrets scan > .secrets.baseline
	detect-secrets audit .secrets.baseline

simulation_id ?= $(error 'simulation_id' is not set)
working_dir ?= $(shell pwd)

.PHONY: run-simulation
run-simulation:
	docker build --pull -t simulations .
	docker run --rm \
		-v ${working_dir}/output:/simulations/output \
		simulations \
		--simulation_id ${simulation_id}
