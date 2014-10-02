build:
	@gulp scripts

test:
	@gulp test

install:
	@npm install
	@node app/setup

clean:
	@gulp clean

.PHONY: build test install clean

