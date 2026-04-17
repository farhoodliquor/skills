---
name: kubernetes-reflector
description: Configure Kubernetes Reflector annotations to mirror secrets and configmaps across namespaces.
---

# Kubernetes Reflector Skill

Configure reflection annotations for [Kubernetes Reflector](https://github.com/emberstack/kubernetes-reflector), a Kubernetes addon that monitors changes to secrets and configmaps and reflects them to mirror resources in other namespaces.

## Annotations Reference

### Source Resource Annotations

Apply to the **source** secret or configmap to permit reflection:

| Annotation | Value | Description |
|---|---|---|
| `reflector.v1.k8s.emberstack.com/reflection-allowed` | `"true"` | Permit this resource to be reflected |
| `reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces` | comma-separated namespaces or regex | Restrict which namespaces can reflect this resource. If omitted, all namespaces are allowed |

**Automatic mirror creation** (optional):

| Annotation | Value | Description |
|---|---|---|
| `reflector.v1.k8s.emberstack.com/reflection-auto-enabled` | `"true"` | Automatically create mirrors in target namespaces |
| `reflector.v1.k8s.emberstack.com/reflection-auto-namespaces` | comma-separated namespaces or regex | Namespaces where auto-mirrors are created. If omitted, all allowed namespaces are used |

### Mirror Resource Annotations

Apply to the **mirror** (destination) resource:

| Annotation | Value | Description |
|---|---|---|
| `reflector.v1.k8s.emberstack.com/reflects` | `namespace/name` | The source resource to reflect (e.g., `default/my-secret`) |
| `reflector.v1.k8s.emberstack.com/reflected-version` | `""` | Reset to empty string to force re-reflection when manually updating the mirror |

## Examples

### Enable Reflection on a Source Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: source-secret
  namespace: default
  annotations:
    reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
    reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: "namespace-1,namespace-2,namespace-[0-9]*"
data:
  ...
```

### Create a Mirror Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mirror-secret
  namespace: namespace-1
  annotations:
    reflector.v1.k8s.emberstack.com/reflects: "default/source-secret"
data:
  ...
```

### Automatic Mirroring (No Manual Mirror Creation)

Annotate the source with `reflection-auto-enabled`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: source-secret
  annotations:
    reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
    reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
    reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: "namespace-1,namespace-2"
```

Reflector will automatically create mirrors in `namespace-1` and `namespace-2` with the same name.

Reflector monitors changes to source objects and copies the following fields:
- `data` for secrets
- `data` and `binaryData` for configmaps

Reflector tracks what was copied by annotating mirrors with the source object version.

## cert-manager Integration

### Certificate (v1.5+)

Secrets created from certificates can enable reflection via `secretTemplate`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
...
spec:
  secretTemplate:
    annotations:
      reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
      reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: ""
```

### Ingress (v1.15+)

Ingress resources can set reflection annotations via `cert-manager.io/secret-template`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    cert-manager.io/secret-template: |
      {"annotations": {"reflector.v1.k8s.emberstack.com/reflection-allowed": "true", "reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces": ""}}
```

## Usage with kubectl

```bash
# Enable reflection on a source secret
kubectl annotate secret -n <namespace> <name> \
  reflector.v1.k8s.emberstack.com/reflection-allowed=true \
  reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces="<comma-separated-namespaces>" \
  --overwrite

# Create a mirror that reflects a source
kubectl annotate secret -n <mirror-namespace> <mirror-name> \
  reflector.v1.k8s.emberstack.com/reflects=<source-namespace>/<source-name> \
  --overwrite

# Force re-reflection on a mirror
kubectl annotate secret -n <mirror-namespace> <mirror-name> \
  reflector.v1.k8s.emberstack.com/reflected-version="" \
  --overwrite
```
