# Creating Declarative YAML for Multizone Deployments

## For a Global Control Plane

First, generate the base installation YAML using this command:

    kumactl install control-plane  --tls-general-ca-secret=kuma-root-ca \
    --tls-general-secret=kuma-tls-general \
    --tls-general-ca-bundle=$(echo "blah") \
    --mode=global > kuma.yaml

To this base YAML, the following two changes need to be made:

1. The `caBundle` value supplied for all webhooks needs to be deleted.
2. All webhooks need to be annotated for the cert-manager [CA Injector](https://cert-manager.io/docs/concepts/ca-injector/) to automatically inject the correct `caBundle` value.

The same Kustomize configuration used for a standalone installation will also work for a global control plane installation (look in the `kuma` directory in this repository). The resulting YAML output is reusable for the installation of any global control plane.

## For a Zone Control Plane

Making the installation YAML for a zone control plane reusable is impractical for two reasons:

1. Each and every zone will have a unique name that is included in the YAML configuration. This very likely will need to be changed for every installation.
2. Each and every zone must make a connection back to the global control plane (provided via the `--kds-global-address` parameter to `kumactl`, which then translates into the `KUMA_MULTIZONE_ZONE_GLOBAL_ADDRESS` environment variable). This, too, will very likely need to be changed for every installation.

However, if the environment variables being passed to the zone control plane were converted into values in the "kuma-control-plane-config" ConfigMap, then it would be possible to use a Kustomize ConfigMapGenerator with the `behavior` field set to "merge" to overwrite generic values with zone-specific values. This would require a separate configuration file and separate Kustomize overlays for each zone with the zone-specific values, and the use of `kustomize build` in order to install each zone control plane. (In contrast, the use of Kustomize for a global control plane or standalone installation is performed once only, to generate the reusable YAML, and is not needed for each use of the reusable YAML.)

Additionally, the same changes outlined above also need to be made to the YAML for a zone control plane. It is possible that the same Kustomize configuration here _may_ work for both standalone and global control plane installations; this has not been tested.
