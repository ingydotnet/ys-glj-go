# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a test project for Glojure AOT (Ahead-of-Time) compilation that demonstrates compiling Clojure code through Glojure to Go and finally to a native binary. The project implements a "99 Bottles of Beer" program as a test case.

## Build Pipeline

The compilation pipeline follows this chain:
1. Clojure (.clj) → Glojure (.glj) via `rewrite.clj` script
2. Glojure (.glj) → Go (.go) via `glj-aot` command
3. Go (.go) → Binary via `go build`

## Development Commands

### Primary Commands
- `make run` - Full build and run pipeline (compiles Clojure→Glojure→Go→Binary and executes with 3 verses)
- `make clean` - Clean generated files (binary, Go files, GLJ files, go.sum)
- `make realclean` - Deep clean including cloned Glojure repository

### Build Process
The Makefile handles dependency management automatically:
- Clones the Glojure fork from `https://github.com/ingydotnet/glojure` (aot-new branch)
- Builds the `glj-aot` command tool
- Auto-installs Go 1.19.3 and Babashka if not present

## Architecture

### Source Structure
- `src/main.clj` - Entry point with main function and 99-bottles implementation
- `src/ys/v0.clj` - Utility library with helper functions (say, dec+, each, rng macros)

### Generated Structure
- `go/` directory contains generated Go files and go.mod
- `glojure/` directory contains cloned Glojure compiler (auto-managed)
- Generated `.glj` files are placed in `glojure/pkg/stdlib/`

### Key Dependencies
- Uses a forked version of Glojure with AOT compilation support
- Requires Go 1.19.3 specifically
- Uses Babashka for running Clojure transformation scripts
- The project depends on the `github.com/glojurelang/glojure` package (local replace)

### Namespace Mapping
The Makefile defines GLJ-NAMESPACES that map Clojure namespaces to file paths:
- `main` → `main.clj` → `go/main.go`
- `ys.v0` → `ys/v0.clj` → `go/ys/v0.go`

## Development Notes

- The project uses makeplus/makes for build system automation
- Generated files are automatically cleaned and rebuilt as needed
- The Glojure repository is managed as a dependency and may have unstable branches
- Post-processing removes Go type annotations (`^Number`, `:tag Number`) from generated code