# URL Redirects

Hyrax can register arbitrary URL paths as redirects to a work or collection's canonical URL. This is the migration safety net for institutions moving from DSpace, CONTENTdm, Islandora, bepress, or any other repository system whose URLs are cited in published scholarship, embedded in LibGuides, indexed by search engines, and bookmarked by researchers — those URLs need to keep resolving after the move.

This feature is **disabled by default** and must be explicitly enabled in two layers.

## Two-layer feature gating

The redirects feature is gated by **two** independent switches:

1. **`Hyrax.config.redirects_enabled?`** — application-level config. Controls whether the schema and properties exist in this Hyrax application at all. Set in `config/initializers/hyrax.rb` or via the `HYRAX_REDIRECTS_ENABLED` environment variable. Default: `false`.

2. **`Flipflop.redirects?`** — per-tenant feature flag. Controls whether *this tenant* uses the registered redirects feature. Only registered when the config is on. Default when registered: `false`. Toggleable per-tenant via the Flipflop admin UI.

| Config | Flipflop | What's true |
|---|---|---|
| off | n/a (unregistered) | The schema is not loaded. The Flipflop feature is not registered. No `redirects` attribute on any resource. No indexer. No route. No controller. m3 profile does not require a `redirects` property. The feature is wholly absent. |
| on | registered, off (default) | The schema is loaded. The `redirects` attribute exists on `Hyrax::Work` and `Hyrax::PcdmCollection`. The indexer is included on resource indexers but emits no Solr field. Routes/controllers/UI gates check Flipflop and stay silent. m3 profile may declare `redirects` (loaded but unused — a warning is emitted on profile validation). |
| on | on | All of the above, plus: the indexer emits `redirects_path_ssim`. The route/controller/UI engage. m3 profile validation **requires** the `redirects` property to be declared and available on `Hyrax::Work` and `Hyrax::PcdmCollection`. |

The two-layer split is deliberate: the application-level config controls *availability* (the schema is structural — toggling it after data is written would orphan persisted entries), and the per-tenant Flipflop controls *use* (each tenant decides at request time).

## Enabling the config

### Via environment variable

```sh
export HYRAX_REDIRECTS_ENABLED=true
```

This is the easiest path for koppie/dassie/sirenia/allinson and for CI environments.

### Via initializer

```ruby
# config/initializers/hyrax.rb
Hyrax.config do |config|
  config.redirects_enabled = true
end
```

This is appropriate when an adopter wants the feature unconditionally without depending on the deploy environment.

### What changes when the config is on

- `config/metadata/redirects.yaml` becomes part of the schema set (visible to `Hyrax::SimpleSchemaLoader#permissive_schema_for_valkrie_adapter` and `Hyrax::Schema(:redirects)`).
- `Hyrax::Work` and `Hyrax::PcdmCollection` include `Hyrax::Schema(:redirects)` (subject to the existing `work_default_metadata` / `collection_include_metadata?` gates so adopters who manage their own work/collection metadata schemas aren't overridden).
- The `:redirects` Flipflop feature is registered and appears in the admin Flipflop UI.
- `Hyrax::Indexers::PcdmObjectIndexer` and `Hyrax::Indexers::PcdmCollectionIndexer` include `Hyrax::Indexers::RedirectsIndexer` (the include itself is conditional on this config; when off, the mixin is not added at all).
- The m3 profile validator runs the redirects-specific check (no error or warning unless the Flipflop is also on, or the profile contains a stale `redirects` property).

### What changes when the config is off

- None of the above happens. Hyrax behaves as if the redirects feature didn't exist.

## Enabling the Flipflop (per tenant)

Once the config is on, the `:redirects` feature appears in the experimental_features group of the Hyrax Flipflop admin UI. Toggling it on for a tenant:

- Causes `Hyrax::Indexers::RedirectsIndexer` to emit the `redirects_path_ssim` field for that tenant's resources.
- Activates the catch-all redirect route and `Hyrax::RedirectsController` (slice 2; see ticket #622).
- Causes the m3 profile validator to **require** a `redirects` property in the tenant's flexible metadata profile (when `flexible: true` mode is also active).

If the Flipflop is on but the m3 profile is missing the `redirects` property, the profile fails validation with a clear error message. Adopters running flexible metadata must add a `redirects` property to their m3 profile before enabling the Flipflop.

## m3 profile requirements (`flexible: true` mode)

Adopters running `HYRAX_FLEXIBLE=true` and choosing to use redirects must declare a `redirects` property in their m3 profile. The minimal declaration:

```yaml
properties:
  redirects:
    available_on:
      class:
        - Hyrax::Work
        - Hyrax::PcdmCollection
    cardinality:
      minimum: 0
    type: redirect
    multiple: true
    predicate: http://samvera.org/ns/hyku/redirects
```

The `type: redirect` token resolves to `Hyrax::Redirect`, a `Valkyrie::Resource` with `path`, `canonical`, and `sequence` sub-attributes.

Validation matrix on profile save (with the config on):

| Flipflop | Property | Result |
|---|---|---|
| off | absent | silent (tenant hasn't opted in) |
| off | present | warning (property is loaded but unused) |
| on | absent | error (property is required) |
| on | present, missing `Hyrax::Work` or `Hyrax::PcdmCollection` in `available_on.class` | error |
| on | present, complete | silent (valid) |

When the config is **off**, an m3 profile that declares `redirects` produces a warning rather than an error. The property is dead — it won't be loaded — but Hyrax doesn't refuse to save the profile.

## Schema details (`flexible: false` mode)

In default (non-flexible) mode the schema lives in `config/metadata/redirects.yaml`:

```yaml
attributes:
  redirects:
    type: redirect
    multiple: true
    form:
      primary: false
    predicate: http://samvera.org/ns/hyku/redirects
    mappings:
      simple_dc_pmh: ~
```

When the config is on, this schema is loaded and `Hyrax::Work` / `Hyrax::PcdmCollection` include it via `Hyrax::Schema(:redirects)`. The schema loader produces:

```ruby
attribute :redirects, Valkyrie::Types::Set.of(Hyrax::Redirect)
```

`Set` (rather than `Array`) is used so instance round-trips through assignment don't re-invoke the Dry::Struct constructor on existing entries — `Array.of(Resource)` raises `can't convert Object into Hash` on `work.redirects = work.redirects`.

When the config is off, the loader filters `redirects.yaml` out of the schema set entirely. The file is on disk but invisible to `permissive_schema_for_valkrie_adapter`, `Hyrax::Schema(:redirects)`, and any other consumer of the simple schema loader.

## Reindexing after enabling

Toggling the config or the Flipflop changes what the indexer emits. Existing records need a reindex to have the new field populated (when both gates open) or removed (when either closes):

```sh
bundle exec rails hyrax:solr:reindex_everything
```

## Disabling

To fully disable: unset `HYRAX_REDIRECTS_ENABLED` (or set `Hyrax.config.redirects_enabled = false`) and reboot. The schema is no longer loaded, the attribute is no longer included on `Hyrax::Work` / `Hyrax::PcdmCollection`, the Flipflop feature is no longer registered, and the indexer mixin is no longer included. Persisted `redirects` entries on records remain in storage (Postgres / Fedora) but are inaccessible because the attribute no longer exists on the model. Re-enabling restores access.

To disable for a specific tenant only, leave the config on and toggle the `:redirects` Flipflop off in that tenant's admin Flipflop UI.

### Caveats

- **`Hyrax::Redirect` (the resource class) is always defined.** The class file is loaded by Rails autoloading as soon as anything references the constant. It costs effectively nothing when unused. The "wholly absent" effect of disabling the config applies to the schema, the attribute on `Hyrax::Work` / `Hyrax::PcdmCollection`, the Flipflop, the indexer, and the m3 profile validator's enforcement — but not to the constant itself.
- **The `disabled_schemas` filter only affects `Hyrax::SimpleSchemaLoader`.** Adopters running `flexible: true` whose m3 profile contains a stale `redirects` property will still see the attribute defined on records loaded via `M3SchemaLoader` even if `Hyrax.config.redirects_enabled?` is false. The m3 profile validator emits a warning in that situation ("the property will be ignored"); follow the warning by removing the `redirects` property from the m3 profile or setting the config back on.

## For contributors

### Why a config *and* a Flipflop?

The schema include on `Hyrax::Work` and `Hyrax::PcdmCollection` runs at class-load time, often triggered by Bulkrax's initializer before the Flipflop facade is wired up. `Hyrax.config.redirects_enabled?` is queryable that early; `Flipflop.redirects?` is not. The config gates structural choices (does the attribute exist on the model? does the schema YAML get loaded?); the Flipflop gates per-tenant behavior at request time (does this tenant see the UI? does the indexer emit values?).

### Calling `Flipflop.redirects?`

The `:redirects` Flipflop feature is only registered when `Hyrax.config.redirects_enabled?` is true. When the config is off, calling `Flipflop.redirects?` raises `NoMethodError`. Any new code that consults the feature flag must short-circuit on the config first:

```ruby
Hyrax.config.redirects_enabled? && Flipflop.redirects?
```

Alternatively, gate the inclusion of the calling code itself on `Hyrax.config.redirects_enabled?` (as the indexer mixin does in `Hyrax::Indexers::PcdmObjectIndexer` and `Hyrax::Indexers::PcdmCollectionIndexer`); then the body can check `Flipflop.redirects?` alone because it only runs when the feature is registered.

## See also

- `documentation/flexible_metadata.md` — m3 profile fundamentals and how the redirects feature interacts with flexible metadata.
- `Hyrax::Redirect` (`app/models/hyrax/redirect.rb`) — the Valkyrie::Resource representing a single redirect entry.
- `Hyrax::Indexers::RedirectsIndexer` (`app/indexers/hyrax/indexers/redirects_indexer.rb`) — the indexer mixin.
- `Hyrax::FlexibleSchemaValidators::RedirectsValidator` (`app/services/hyrax/flexible_schema_validators/redirects_validator.rb`) — the m3 profile validator.
