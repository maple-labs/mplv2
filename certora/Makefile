munged-simple: $(wildcard ../contracts/*.sol) patches/applyHarnessInflationModule.patch
	@rm -rf munged-simple
	@cp -r ../contracts munged-simple
	@patch -p2 -d munged-simple < patches/applyHarnessInflationModule.patch

clean:
	rm -rf munged-simple
