Hyrax Helm
==========

This [Helm][helm] chart provides configurable deployments for Hyrax applications
to [Kubernetes][k8s] clusters. It seeks to be a complete but flexible
production-ready setup for Hyrax applications. By default it deploys:

  - A Hyrax-based Rails application
  - Fedora Commons v4.7
  - Postgresql
  - Solr (in a cloud configuration, including Apache Zookeeper)
  - Redis

## Minimum requirements

- Kubernetes 1.21
- Helm 3

## A base Hyrax deployment

Because Hyrax is a [Rails Engine][engine]---not a stand-alone application---
deploying it requires us to have a specific application. This chart assumes that
the user has a container image based on `samveralabs/hyrax` (see:
[CONTAINERS.md][containers]) that includes their application. Point the chart at
your image by setting the `image.repository` and `image.tag` values.

By default, the chart deploys [images][dassie-images] for Hyrax's development
application, [`dassie`][dassie].

For application configuration, we take our queues from [12-factor][twelve]
methodology. Applications using environment variables to manage their
configuration can be easily reconfigured across different releases using this
chart; e.g. the same chart can be used to deploy sandbox, staging, and
production environments.

The chart populates the following environment variables:

| Variable          | Description                    | Condition                                |
|-------------------|--------------------------------|------------------------------------------|
| CH12N_TOOL        | Tool for characterization      | `fits.enabled` or `externalFits.enabled` |
| DB_PASSWORD       | Postgresql password            | n/a                                      |
| DB_PORT           | Postgresql service port        | n/a                                      |
| DB_HOST           | Postgresql hostname            | n/a                                      |
| DB_USERNAME       | Postgresql username            | n/a                                      |
| MEMCACHED_HOST    | Memcached host                 | `memcached.enabled`                      |
| RACK_ENV          | app environment ('production') | n/a                                      |
| RAILS_ENV         | app environment ('production') | n/a                                      |
| REDIS_HOST        | Redis service host             | `redis.enabled`                          |
| FCREPO_BASE_PATH  | Fedora Commons root path       | n/a                                      |
| FCREPO_HOST       | Fedora Commons host            | n/a                                      |
| FCREPO_PORT       | Fedora Commons port            | n/a                                      |
| FCREPO_REST_PATH  | Fedora Commons REST endpoint   | n/a                                      |
| FITS_SERVLET_URL  | URL for FITS servlet           | `fits.enabled` or `externalFits.enabled` |
| SKIP_HYRAX_ENGINE_SEED   | Flag to load Hyrax engine seed file | n/a                          |
| SOLR_ADMIN_USER   | Solr user for basic auth       | n/a                                      |
| SOLR_ADMIN_PASSWORD | Solr password for basic auth | n/a                                      |
| SOLR_COLLECTION_NAME | The name of the solr collection to use | n/a                           |
| SOLR_CONFIGSET_NAME | The name of the solr configset to use for config management tasks | n/a |
| SOLR_HOST         | Solr service host              | n/a                                      |
| SOLR_PORT         | Solr service port              | n/a                                      |
| SOLR_URL          | Solr service full URL          | n/a                                      |

## With an external SolrCloud

By default, this chart deploys and manages an internal SolrCloud deployment,
complete with its own ZooKeeper service.

To use an existing or externally managed SolrCloud, use the chart values:

  - `solr.enabled`: false
  - `externalSolrHost`: "mySolr.hostname.example.com"
  - `externalSolrUser`: "admin"
  - `externalSolrPassword`: "the_admin_password"
  - `externalSolrCollection`: "a_collection_name"

The chart will attempt to upload a ConfigSet for Hyrax matching the deployment's
"fullname" and assign it to the collection. This is achieved through the Solr
Collections API, and authentication _must_ be enabled in the external Solr for
this to work.

If you want to manage your ConfigSet manually, disable this behavior with
`--set loadSolrConfigSet=false`.

## With an external Fedora Commons Repository

By default, this chart deploys a local Fedora Repository, backed by the
application's Postgresql system.

To use an existing or external `fcrepo` instance, use the chart values:

  - `fcrepo.enabled`: false
  - `externalFcrepoHost`: "myfedora.hostname.example.com"


# Optional Fits Service

Running fits as a servlet will result in much faster fits responses. This is because the loading cost of the
various Java components far out weighs the processing time of those components.

To enable fits as a service:

  - ``fits.enabled: true` or `externalFits.enabled: true` and specify the
    existing `externalFits.url`

## For DevOps:

For those interested in trying out or contributing to this Chart, it's helpful
to setup a simple cluster locally. Various projects exist to make this easy; we
recommend [`k3d`][k3d] or [minikube][minikube].

### Getting Started with K3D

Make sure you have `docker`, `k3d`, and `helm` installed (e.g., for OSX run `brew install k3d` and `brew install helm`; and install `Docker Desktop`).

Make sure you have Docker up and running.

Run the following command; it will pull images and when finished you'll have a Kubernetes cluster running across a number of Docker containers.

```sh
k3d cluster create dev-cluster --api-port 6550 -p 80:80@loadbalancer --agents 3
```

When it's done, you should see something like the following output:

```sh
INFO[0251] You can now use it like this:
kubectl config use-context k3d-dev-cluster
kubectl cluster-info
```

Then update the helm charts with the following:

```sh
HELM_EXPERIMENTAL_OCI=1 helm dependency update chart/hyrax
```

If your `helm` version is before 3.8, without the `HELM_EXPERIMENTAL_OCI=1` switch you might see the following error:

```sh
repository oci://ghcr.io/samvera is an OCI registry: this feature has been marked as experimental and is not enabled by default. Please set HELM_EXPERIMENTAL_OCI=1 in your environment to use this feature”
```

With the following command, you'll next want to install hyrax into a namespace.  The namespace directive helps convey the meaning of the kubernetes cluster; and helps you manage all of the resources for that namespace (e.g., "production" or "testing").

```sh
helm install --create-namespace --namespace hyrax dassie chart/hyrax
```

This creates the Helm release named `dassie`, in the namespace `hyrax`.  This command will echo instructions for exposing the running application URL.

You'll be downloading a lot of packages, and this will take quite a bit of time (depending on your bandwidth, and depending on how your ISP allocates resources, you may experience network connectivity issues that are VERY hard to troubleshoot; at least that was Jeremy's experience as he kept getting `ImagePullBackOff` errors.  The recommendation, find a different network to install Kubernetes).

You can check the status by running `kubectl --namespace hyrax get pods --watch`.  To learn more about a failed pod, you can run `kubectl describe pod <named pod> --namespace hyrax`.  The events section (at the bottom of the output) will be useful for troubleshooting.

Some shell commands of house cleaning and destruction:

*  To stop the cluster: `k3d cluster stop dev-cluster`.
*  To delete the cluster: `k3d cluster delete dev-cluster`.
*  Remove existing docker instances: `docker rm $(docker ps -q -f status=exited)`
*  Remove hanging docker instances: `docker rm $(docker ps -a -q) -f`
*  Removing dangling docker images: `docker rmi $(docker images -f "dangling=true" -q)`

## Building and Pushing the Chart Package

We currently build and push new chart versions manually. This needs to happen
any time the chart version in [`Chart.yaml`](./Chart.yaml) is incremented.

To publish the Hyrax chart, you'll need to be in one of the GitHub groups with
push permissions. These groups are:

  - `@samvera/admins`
  - `@samvera/hyrax` (and all its subgroups)

To build the package, it's helpful to have a clean checkout of the current
`main` branch, then:

```sh
HELM_EXPERIMENTAL_OCI=1 helm dependency update chart/hyrax
HELM_EXPERIMENTAL_OCI=1 helm package chart/hyrax
HELM_EXPERIMENTAL_OCI=1 helm push hyrax-[VERSION].tgz oci://ghcr.io/samvera/charts
```


[containers]: ../../CONTAINERS.md#hyrax-image
[dassie]: ../../.dassie/README.md
[dassie-image]: https://hub.docker.com/r/samveralabs/dassie
[engine]: https://guides.rubyonrails.org/engines.html
[helm]: https://helm.sh
[k3d]: https://k3d.io
[k8s]: https://kubernetes.io
[minikube]: https://minikube.sigs.k8s.io/docs/
