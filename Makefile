build:
	@gulp scripts

test:
	@gulp test-and-exit

install:
	@npm install

clean:
	@gulp clean

.PHONY: build test install clean

