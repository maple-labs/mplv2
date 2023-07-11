munged-simple: $(wildcard ../contracts/*.sol) applyHarnessInflationModule.patch
	@rm -rf munged-simple
	@cp -r ../contracts munged-simple
	@patch -p2 -d munged-simple < applyHarnessInflationModule.patch

clean:
	rm -rf munged-simple
