build:
	@scripts/build.sh -p default

deploy:
	@scripts/deploy.sh

localDeploy:
	@scripts/localDeploy.sh

release:
	@scripts/release.sh

test:
	@scripts/test.sh -p default

verify:
	@certora/scripts/verify.sh

verify-sanity:
	@certora/scripts/verify-sanity.sh
