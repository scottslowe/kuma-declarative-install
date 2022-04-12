# Creating Declarative YAML to Install Kuma

This repository contains instructions and resources to create reusable YAML for installing [Kuma](https://kuma.io) in a declarative fashion. This guide was written for Kuma 1.5.x, and will not work with previous versions of Kuma. (This repository contains tagged releases for earlier versions of Kuma in the event you need instructions for an earlier release.)

## Prerequisites

1. You will need a working Kubernetes cluster with a CNI plugin installed. These instructions were tested with Kubernetes 1.22 and the Calico CNI plugin. (Other CNI plugins should work, but weren't tested.)
2. You will need the `kumactl` command-line utility installed. Both Kuma 1.5.0 and Kuma 1.5.1 were tested for these instructions. Refer to [the Kuma docs](https://kuma.io/docs/1.5.x/) for installing `kumactl`.
3. You will need [cert-manager](https://cert-manager.io) installed on the Kubernetes cluster. Follow the instructions [here](https://cert-manager.io/docs/installation/) to install cert-manager. These instructions were tested with cert-manager 1.8.0, but older versions back as far as 1.5.4 should work equally well.

## Creating Reusable Declarative YAML for Kuma

The process for creating reusable YAML to install Kuma looks like this:

1. Create the base YAML using `kumactl install control-plane`.
2. Replace references to embedded TLS assets in the output of `kumactl install control-plane` with references to Secrets that will be managed by cert-manager. You can make these changes manually, or you can use a tool like [Kustomize](https://kustomize.io).

### Creating Base Installation YAML

Start by generating the base YAML for installing Kuma with `kumactl`:

    kumactl install control-plane --tls-general-ca-secret=kuma-root-ca \
    --tls-general-secret=kuma-tls-general \
    --tls-general-ca-bundle=$(echo "blah") > kuma.yaml

`kumactl` _requires_ the use of the `--tls-general-ca-bundle` parameter, but the value specified here is irrelevant (you will remove the output of this flag in the next step).

### Making the Installation YAML Reusable

To make the installation YAML generated by `kumactl` reusable, two changes need to be made:

1. The `caBundle` value supplied for all webhooks needs to be deleted.
2. All webhooks need to be annotated for the cert-manager [CA Injector](https://cert-manager.io/docs/concepts/ca-injector/) to automatically inject the correct `caBundle` value.

The `kuma` directory in this repository contains resources for using Kustomize to make these changes.

The `policy` directory in this repository contains Rego tests (intended to be used with `conftest`) to verify that the installation YAML does not contain artifacts that would make it not reusable.

## Using the Reusable Declarative YAML

Once the changes above have been made, the resulting YAML can be reused over and over again. However, since all the TLS assets were replaced with cert-manager resources, those must be created first.

### Create TLS Assets

This repository builds on the information and resources in [the "kuma-cert-manager" GitHub repository](https://github.com/scottslowe/kuma-cert-manager); refer to that repository for additional details on using cert-manager to replace TLS assets used by Kuma. This is _critical_ to the reusable YAML; TLS assets will be declaratively defined and created by cert-manager.

Make sure that all Secret names created by cert-manager are appropriately referenced in the Kuma installation YAML, as generated by `kumactl install control-plane`. In particular, the Secret for the root CA certificate and the general TLS certificate must be correctly referenced (these are controlled by the `--tls-general-ca-secret` and `--tls-general-secret` parameters).

The `tls-assets.yaml` file in this repository contains definitions for the required cert-manager resources.

### Apply the Reusable Declarative YAML

Set your `kubectl` context to the correct cluster with appropriate credentials, and then apply the manifest:

    kubectl apply -f modified-kuma-yaml-file.yaml

As long as cert-manager is installed on the target cluster, you can re-use this same YAML file over and over again with no changes (you just need to create the TLS assets with cert-manager first).

## Caveats/Limitations

These instructions only apply to standalone (single-zone) Kubernetes-based installations of Kuma. Multi-zone installations are discussed in [`multizone.md`](./multizone.md). Universal zones are not addressed here.
