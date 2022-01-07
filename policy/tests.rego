package main

general_ca_vol_present = true {
    input.kind == "Deployment"
    vols := input.spec.template.spec.volumes[_]
    vols.name == "general-ca-crt"
}

general_ca_vol_incorrect = true {
    input.kind == "Deployment"
    vols := input.spec.template.spec.volumes[_]
    vols.name == "general-ca-crt"
    not vols.secret.secretName == "kuma-root-ca" # Should match secret for CA certificate
}

warn[msg] {
    input.kind == "Deployment"
    env := input.spec.template.spec.containers[0].env[_]
    env.name == "KUMA_RUNTIME_KUBERNETES_INJECTOR_CA_CERT_FILE"
    not env.value == "/var/run/secrets/kuma.io/ca-cert/ca.crt"
    msg = "KUMA_RUNTIME_KUBERNETES_INJECTOR_CA_CERT_FILE is not set correctly for CA of custom TLS certificate"
}

warn[msg] {
    input.kind == "Deployment"
    not general_ca_vol_present
    msg = "Additional volume not defined for CA of custom TLS certificate"
}

warn[msg] {
    input.kind == "Deployment"
    general_ca_vol_incorrect
    msg = "Additional volume for CA of custom TLS certificate not configured correctly"
}

general_ca_crt_volume_mounted = true {
    input.kind == "Deployment"
    mounts := input.spec.template.spec.containers[0].volumeMounts[_]
    mounts.mountPath == "/var/run/secrets/kuma.io/ca-cert"
    mounts.name == "general-ca-crt"
    mounts.readOnly == true
}

warn[msg] {
    input.kind == "Deployment"
    not general_ca_crt_volume_mounted
    msg = "Additional volume for CA of custom TLS certificate not mounted or incorrectly mounted in container"
}

warn[msg] {
    input.kind == "MutatingWebhookConfiguration"
    some i; input.webhooks[i].clientConfig.caBundle
    msg = "caBundle value not removed for a mutating webhook"
}

warn[msg] {
    input.kind == "ValidatingWebhookConfiguration"
    some i; input.webhooks[i].clientConfig.caBundle
    msg = "caBundle value not removed for a validating webhook"
}

warn[msg] {
    input.apiVersion == "admissionregistration.k8s.io/v1"
    not input.metadata.annotations["cert-manager.io/inject-ca-from"]
    msg = "cert-manager CA injection annotation missing from a webhook"
}
