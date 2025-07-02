# Makefile for OpenShift Virtualization UDN Networking

.PHONY: help deploy start-vm stop-vm console status clean

# Configuration
NAMESPACE := vm-guests
VM_NAME := fedora-vm-with-udn

.DEFAULT_GOAL := help

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

deploy: ## Deploy UDN networking and test resources
	oc apply -f base/namespaces/vm-guests-namespace.yaml
	oc apply -f base/network/udn/vm-layer2-udn.yaml
	oc apply -f base/network/udn/vm-layer2-nad.yaml
	oc apply -f examples/virtual-machines/udn/fedora-vm-with-udn.yaml

start-vm: ## Start the test VM
	oc patch vm $(VM_NAME) -n $(NAMESPACE) --type merge -p '{"spec":{"running":true}}'

stop-vm: ## Stop the test VM
	oc patch vm $(VM_NAME) -n $(NAMESPACE) --type merge -p '{"spec":{"running":false}}'

console: ## Connect to VM console
	virtctl console $(VM_NAME) -n $(NAMESPACE)

status: ## Show resource status
	oc get udn,net-attach-def,vm,vmi,svc -n $(NAMESPACE)

clean: ## Remove all resources
	oc delete -f examples/virtual-machines/udn/fedora-vm-with-udn.yaml --ignore-not-found
	oc delete -f base/network/udn/vm-layer2-nad.yaml --ignore-not-found
	oc delete -f base/network/udn/vm-layer2-udn.yaml --ignore-not-found 