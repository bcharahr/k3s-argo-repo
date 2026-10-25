# k3s-argo-repo

GitOps repository for deploying applications to the k3s cluster with Argo CD.

## Repository layout

```text
bootstrap/
	root-app.yaml          # Apply once to let Argo CD manage the ApplicationSet
argocd/
	applicationset.yaml    # Discovers and deploys apps/* directories
apps/
	_template/             # Starter files; excluded from discovery
	<app-name>/
		Chart.yaml           # Local Helm chart metadata
		values.yaml          # Chart-specific Helm values
		templates/           # Kubernetes resources rendered by the chart
```

## Bootstrap

Install Argo CD in the cluster first, then ensure it can access this GitHub
repository over HTTPS. From a machine with `kubectl`
configured for the cluster, apply `bootstrap/root-app.yaml`:

```sh
kubectl apply -n argocd -f bootstrap/root-app.yaml
```

The root Application watches `argocd/` on the `main` branch and installs the
ApplicationSet. The ApplicationSet discovers each directory under `apps/`
except `_template`, then creates one Argo CD Application per directory.

## Add a local Helm chart application

1. Copy `apps/_template/` to `apps/<app-name>/` (use a DNS-safe name such as
	 `pocketid`, `vault`, or `registry`).
2. Update `Chart.yaml` with the chart name and app version. The chart name
	 should match the directory name. For example:

	 ```yaml
	 apiVersion: v2
	 name: pocketid
	 description: Helm chart for Pocket ID
	 type: application
	 version: 0.1.0
	 appVersion: "1.0.0"
	 ```

3. Add the chart's Kubernetes templates under `templates/` and configure them
	 with `values.yaml`. Commit and push to `main`.

The ApplicationSet creates an Argo CD Application for each app directory,
renders the local chart, and creates a namespace matching the directory name.
Each app is automatically synchronized, pruned, and self-healed. This template
is only chart metadata: add Kubernetes templates or vendor chart dependencies
before expecting it to deploy workloads. Removing an app directory removes its
generated Argo CD Application; review Argo CD's resource-deletion behavior if
you need to retain its cluster resources.

## Notes

- The root Application and ApplicationSet currently follow `main`; update both
	target revisions if you use a different default branch.
- The generated Applications use Argo CD's `default` AppProject. Restrict that
	project or define a dedicated project if you need tighter source/namespace
	permissions.
- This layout uses local Helm charts. If you prefer to consume upstream Pocket
	 ID, Vault, or registry charts instead of maintaining chart templates here,
	 switch those apps to Argo CD's remote Helm chart source configuration.

## Mario example

The `apps/mario/` chart exposes the game at `https://mario.3aevolution.com`
through the Traefik Ingress controller. Point that hostname's DNS record at
your ingress endpoint. The chart requests TLS using the `mario-tls` Secret.
Set `ingress.clusterIssuer` in `apps/mario/values.yaml` to the name of your
cert-manager ClusterIssuer if cert-manager should create that Secret. If you
already have a wildcard certificate, ensure its TLS Secret is available in
the `mario` namespace and set `ingress.tls.secretName` to that Secret's name.

This example uses the third-party `pengbai/docker-supermario` image; review
the image and its provenance before using it in your cluster.
