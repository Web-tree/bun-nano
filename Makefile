.PHONY: build verify all clean

all: build verify

build:
	bash scripts/build-all.sh

verify:
	bash scripts/verify.sh

clean:
	-docker rmi $$(docker images -q bun-nano) 2>/dev/null || true
