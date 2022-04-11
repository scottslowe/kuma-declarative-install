package main

general_tls_cert_vol_incorrect = true {
    input.kind == "Deployment"
    vols := input.spec.template.spec.volumes[_]
    vols.name == "general-tls-cert"
    not vols.secret.secretName == "kuma-tls-general" # Should match secret for TLS certificate
}

general_tls_cert_ca_vol_incorrect = true {
    input.kind == "Deployment"
    vols := input.spec.template.spec.volumes[_]
    vols.name == "general-tls-cert-ca"
    not vols.secret.secretName == "kuma-root-ca" # Should match secret for CA certificate
}

warn[msg] {
    input.kind == "Deployment"
    general_tls_cert_vol_incorrect
    msg = "Volume for custom TLS certificate not configured correctly"
}

warn[msg] {
    input.kind == "Deployment"
    general_tls_cert_ca_vol_incorrect
    msg = "Volume for CA of custom TLS certificate not configured correctly"
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
