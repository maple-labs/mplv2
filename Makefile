build:
	@scripts/build.sh -p default

coverage:
	@scripts/coverage.sh

deploy:
	@scripts/deploy.sh

localDeploy:
	@scripts/localDeploy.sh

release:
	@scripts/release.sh

test:
	@scripts/test.sh -p default

validate:
	@FOUNDRY_PROFILE=production forge script Validate$(step)

verify:
	@certora/scripts/verify.sh

verify-sanity:
	@certora/scripts/verify-sanity.sh
