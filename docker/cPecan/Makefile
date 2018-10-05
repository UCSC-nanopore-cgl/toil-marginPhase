# Definitions
git_commit ?= $(shell git log --pretty=oneline -n 1 | cut -f1 -d " ")
name = tpesout/cpecan
tag = ${git_commit}

# Steps
build:
	docker build -t ${name}:${tag} .
	docker tag ${name}:${tag} ${name}:latest
	rm -rf tmp.cPecan

push: build
	# Requires ~/.dockercfg
	docker push ${name}:${tag}
	docker push ${name}:latest
