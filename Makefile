build:
	@scripts/build.sh -p default

localDeploy:
	@scripts/localDeploy.sh

release:
	@scripts/release.sh

test:
	@scripts/test.sh -p default
