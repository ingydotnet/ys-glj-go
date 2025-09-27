# This stuff auto installs Go and Babashka (for rewrite.clj):
M := .cache/makes
$(shell [ -d $M ] || git clone -q https://github.com/makeplus/makes $M)
include $M/init.mk
GO-VERSION ?= 1.19.3
include $M/go.mk
include $M/ys.mk
include $M/babashka.mk
include $M/clean.mk
include $M/shell.mk


# Glojure fork with --aot support:
GLOJURE-REPO := https://github.com/ingydotnet/glojure
GLOJURE-REPO := git@github.com:ingydotnet/glojure

GLOJURE-BRANCH := glj-cli-aot-flag
GLOJURE-BRANCH := aot-small-fixes

ifeq (linux,$(OS-NAME))
GLOJURE-OS-ARCH := linux_amd64
else ifeq (macos,$(OS-NAME))
GLOJURE-OS-ARCH := darwin_arm64
endif

GLOJURE-DIR := glojure
GLOJURE-GLJ-BIN := $(GLOJURE-DIR)/bin/$(GLOJURE-OS-ARCH)
GLOJURE-GLJ-CMD := $(GLOJURE-GLJ-BIN)/glj

override export PATH := $(GLOJURE-GLJ-BIN):$(PATH)

YS-FILES := \
  src/99-bottles.ys \
  src/ys/v0.ys \

GLJ-FILES := $(YS-FILES:src/%=glj/%)
GLJ-FILES := $(GLJ-FILES:%.ys=%.glj)

GO-FILES := $(YS-FILES:src/%=go/%)
GO-FILES := $(GO-FILES:%.ys=%.go)

MAKES-CLEAN := 99-bottles glj go
MAKES-REALCLEAN := $(GLOJURE-DIR)/bin
MAKES-DISTCLEAN := .cache

#-------------------------------------------------------------------------------
# Inputs are .clj files in ./src/ directory.
# Later those will be generated from .ys files.
#-------------------------------------------------------------------------------

# Test with `make run`. Should print 3 verses of "99 bottles of beer".
test: 99-bottles
	@echo
	time ./99-bottles 3

# go build the 99-bottles program.
99-bottles: $(GO) $(GLJ-FILES) $(GO-FILES) go/go.mod
	(cd go && go mod tidy && go build)
	[[ -f go/99-bottles && -x go/99-bottles ]]
	mv go/99-bottles $@

distclean::
ifneq (,$(wildcard $(GLOJURE-DIR)))
	-$(MAKE) -C $(GLOJURE-DIR) $@
	$(RM) -fr $(GLOJURE-DIR)
endif

# Use babashka to run the rewrite.clj faster.
glj/%.glj: src/%.ys $(YS) $(BB) | $(GLOJURE-DIR)
	mkdir -p $(dir $@)
	( \
		if [[ $@ == *99-bottles* ]]; then \
			echo '(ns main (:require [ys.v0 :refer :all]))'; \
		fi; \
		ys -c $< | \
		if [[ $@ == *99-bottles* ]]; then \
			perl -pe 's/^\(apply main ARGS\)//' | \
			perl -pe 's{ys\.std/}{}'; \
		else \
			cat; \
		fi; \
		if [[ $@ == *99-bottles* ]]; then \
			echo '(defn -main [& argv] (apply main (map-parse argv)))'; \
		fi; \
	) | \
	bb $(GLOJURE-DIR)/scripts/rewrite-core/rewrite.clj /dev/stdin | \
	perl -pe 's/\^Number //g; s/:tag Number//g' > $@

# AOT generate .go files in the ./go/ directory/.
go/%.go: glj/%.glj $(GLOJURE-GLJ-CMD)
	mkdir -p $(dir $@)
	GLJPATH=glj $(GLOJURE-GLJ-CMD) --aot $< > $@

define go_mod
module 99-bottles

go 1.19

require github.com/glojurelang/glojure v0.0.0

replace github.com/glojurelang/glojure => ../$(GLOJURE-DIR)
endef
export go_mod

go/go.mod:
	mkdir -p $(dir $@)
	echo "$$go_mod" > $@

# Build the glj-aot command binary that compiles .glj input to .go output.
$(GLOJURE-GLJ-CMD): $(GLOJURE-DIR) $(GO)
	cd $(GLOJURE-DIR) && make build
	[[ -f $@ && -x $@ ]]

# Clone the Glojure repo.
$(GLOJURE-DIR):
	git clone $(GLOJURE-REPO) \
		--branch $(GLOJURE-BRANCH) \
		$(GLOJURE-DIR)
