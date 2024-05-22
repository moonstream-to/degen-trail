.PHONY: clean generate regenerate test docs redocs forge

build: forge bin/trailmix bin/jj

rebuild: clean generate build

bin/trailmix:
	mkdir -p bin
	go build -o bin/trailmix ./trailmix

bin/jj: bindings/JackpotJunction/JackpotJunction.go
	mkdir -p bin
	go build -o bin/jj ./jj

bindings/JackpotJunction/JackpotJunction.go: forge
	mkdir -p bindings/JackpotJunction
	seer evm generate --package JackpotJunction --output bindings/JackpotJunction/JackpotJunction.go --foundry out/JackpotJunction.sol/JackpotJunction.json --cli --struct JackpotJunction

test:
	forge test -vvv

clean:
	rm -rf out/*

forge:
	forge build

docs:
	forge doc

redocs: clean docs
