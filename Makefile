.PHONY: clean generate regenerate test docs redocs forge

build: forge bin/trailmix

rebuild: clean generate build

bin/trailmix:
	mkdir -p bin
	go build -o bin/trailmix ./trailmix

test:
	forge test -vvv

clean:
	rm -rf out/*
	rm stamper/TokenboundERC20.go stamper/BindingERC721.go

forge:
	forge build

docs:
	forge doc

redocs: clean docs
