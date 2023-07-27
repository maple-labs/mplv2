# Certora Guide

This README describes how to run the specification defined in this repository via Certora.

## Setup

For installation locally please follow the instructions in the official certora documentation [here](https://docs.certora.com/en/latest/docs/user-guide/getting-started/install.html).

Steps include:
- Installing the prerequisites python, java and the solidity compiler
- Installing the Certora Prover python package
- Setting the premium key environment variable (optional)
- Adding the solc binary to your PATH (optional)
- Installing the certora VS code extensions (optional)


## Run the spec

cd into the root directory of the project and run the following command:

```sh
make verify
```
