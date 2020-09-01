Fedora Commons Helm Chart
=========================

Fedora is the flexible, modular, open source repository platform with native
linked data support.

## Installation

```sh
helm dep up chart/fcrepo
helm install fcrepo chart/fcrepo
```

## Configuration

By default, this chart deploys with Postgresql as the backend for Fedora.
Without other configuration, it will deploy a new Postgresql instance/database
as a service available to the `fcrepo` deployment.

In practice, users may want to forego installing postgres for two reasons:

_First_, when you are deploying Fedora into a more complex application
environment you may wish to reuse an existing Postgres instance already
maintained with that environment.

In this case, `fcrepo` should be deployed with postgresql explictly disabled, an
`exernalDatabaseUsername`, and an `fcrepoSecretName`. `fcrepoSecretName` must
correspond to an existing secret providing `DATABASE_PASSWORD`, `DATABASE_HOST`,
and `JAVA_OPTS`.

Optionally, a `externalDatabaseName` may be given to avoid collissions in the
case that the default `fcrepo` is not an acceptable database name.

This is usually done in the context of a parent chart which provides the postgresql instance, for example:

```yaml
fcrepo:
  enabled: true
  fcrepoSecretName: "mychart.fcrepo.fullname"
  externalDatabaseUsername: "mydbuser"
  servicePort: 8080
  postgresql:
    enabled: false
```

_Second_, because they want to use another backend for Fedora. This use case is broadly unsupported here. In theory, you can get a default (Infinispan) configuration by setting `postgresql.enabled` to `false`. **THIS CONFIGURATION IS UNTESTED AND UNSUPPORTED**:

```sh
helm install --set postgresql.enabled=false fcrepo-test chart/fcrepo
```
