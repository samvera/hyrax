# URL Redirects

Hyrax can register arbitrary URL paths as redirects to a work or collection's permanent URL. This is the migration safety net for institutions moving from DSpace, CONTENTdm, Islandora, bepress, or any other repository system whose URLs are cited in published scholarship, embedded in LibGuides, indexed by search engines, and bookmarked by researchers — those URLs need to keep resolving after the move.

This feature is **disabled by default** and must be explicitly enabled in two layers.

## Two-layer feature gating

The redirects feature is gated by **two** independent switches:

1. **`Hyrax.config.redirects_enabled?`** — application-level config. Controls whether the schema and properties exist in this Hyrax application at all. Set in `config/initializers/hyrax.rb` or via the `HYRAX_REDIRECTS_ENABLED` environment variable. Default: `false`.

2. **`Flipflop.redirects?`** — runtime feature flag. Controls whether the redirects feature is active. Only registered when the config is on. Default when registered: `false`. Toggleable via the Flipflop admin UI. Multi-tenant host apps (e.g. Hyku) can resolve this flag per tenant via Flipflop's strategy chain.

| Config | Flipflop | What's true |
|---|---|---|
| off | n/a (unregistered) | The schema is not loaded. The Flipflop feature is not registered. No `redirects` attribute on any resource. No indexer. The middleware short-circuits before any work. m3 profile does not require a `redirects` property. The feature is wholly absent. |
| on | registered, off (default) | The schema is loaded. The `redirects` attribute exists on `Hyrax::Work` and `Hyrax::PcdmCollection`. The indexer is included on resource indexers but emits no Solr field. The middleware and UI gates check Flipflop and stay silent. m3 profile may declare `redirects` (loaded but unused — a warning is emitted on profile validation). |
| on | on | All of the above, plus: the indexer emits `redirects_path_tesim` (for show-page display). The middleware resolves alias paths against the `hyrax_redirect_paths` table; the UUID-to-display before_action engages on the show controllers; the UI shows the Aliases tab. m3 profile validation **requires** the `redirects` property to be declared with `type: hash` and available on at least one work or collection class declared in the profile. |

The two-layer split is deliberate: the application-level config controls *availability* (the schema is structural — toggling it after data is written would orphan persisted entries), and the Flipflop controls *use* at request time.

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
- `Hyrax::Work` includes `Hyrax::Schema(:redirects)` when `work_default_metadata` is true; `Hyrax::PcdmCollection` includes it when `collection_include_metadata?` is true. The form-side `redirects` property is installed per-resource at form initialization: `Hyrax::Forms::ResourceForm#initialize` checks whether the resource responds to `redirects` and, if so, installs `Hyrax::FormFields(:redirects)` on the form's singleton class. This single check handles all four combinations of base-class metadata gates and per-class flexibility (flex-false models that include the schema, flex-true models whose m3 profile declares `redirects`, and the two cases where neither applies). The check runs *after* any flexible-mode resource reconstruction so it sees the resource Reform will use, not a pre-reconstruction copy whose singleton class may still carry attributes from an older m3 schema version.
- The `:redirects` Flipflop feature is registered and appears in the admin Flipflop UI.
- `Hyrax::Indexers::PcdmObjectIndexer` and `Hyrax::Indexers::PcdmCollectionIndexer` include `Hyrax::Indexers::RedirectsIndexer` (the include itself is conditional on this config; when off, the mixin is not added at all).
- The m3 profile validator runs the redirects-specific check (no error or warning unless the Flipflop is also on, or the profile contains a stale `redirects` property).

### What changes when the config is off

- None of the above happens. Hyrax behaves as if the redirects feature didn't exist.

## Enabling the Flipflop

Once the config is on, the `:redirects` feature appears in the experimental_features group of the Hyrax Flipflop admin UI. Toggling it on:

- Causes `Hyrax::Indexers::RedirectsIndexer` to emit the `redirects_path_tesim` field, which powers the show-page display of registered aliases.
- Activates `Hyrax::Redirects::Middleware` for request-time path resolution and the `Hyrax::RedirectToDisplayUrl` before_action on the show controllers for the UUID-to-display redirect.
- Causes the m3 profile validator to **require** a `redirects` property in the flexible metadata profile (when `flexible: true` mode is also active).

If the Flipflop is on but the m3 profile is missing the `redirects` property, the profile fails validation with a clear error message. Adopters running flexible metadata must add a `redirects` property to their m3 profile before enabling the Flipflop.

## m3 profile requirements (`flexible: true` mode)

Adopters running `HYRAX_FLEXIBLE=true` and choosing to use redirects must declare a `redirects` property in their m3 profile. The minimal declaration:

```yaml
properties:
  redirects:
    available_on:
      class:
        - GenericWork
        - CollectionResource
    cardinality:
      minimum: 0
    display_label:
      default: Redirects
    type: hash
    multiple: true
    form:
      display: false
    indexing:
      - editor_only
    predicate: http://samvera.org/ns/hyku/redirects
    range: http://www.w3.org/2001/XMLSchema#string
    view:
      render_term: redirects_path
      render_as: redirects_label
      html_dl: true
```

The `form:` block is required in m3. Without it, the m3 form-definition loader skips the property (its filter drops attributes with empty `form_options`), and the Aliases tab errors when the partial reads `f.object.redirects`. The Aliases UI is rendered by `_form_redirects.html.erb`, not by the auto-generated form, so `display: false` is the right value here.

The `display_label` and `range` entries are required for profile validation. `display_label.default` controls the label that appears next to the redirects field on show pages.

The `indexing: [editor_only]` entry and the `view:` block together opt the redirects field into the show-page display described below in [Displaying redirect aliases on show pages](#displaying-redirect-aliases-on-show-pages). Both are required for that display to appear with editor-or-admin visibility. Note the placement: `editor_only` is an entry in the `indexing:` array (read by `Hyrax::SchemaLoader::AttributeDefinition#editor_only?`); `render_term`, `render_as`, and `html_dl` are inside the `view:` block. Non-flexible mode structures `editor_only` differently — see [Schema details](#schema-details-flexible-false-mode) below.

Each redirect entry is a plain hash with `path` and `display_url` keys, persisted as JSONB on the parent resource. The `type: hash` token resolves to `Dry::Types['hash']`, which round-trips entries through Postgres without the sub-field stripping a nested `Valkyrie::Resource` would suffer. `available_on.class` must include at least one work or collection class declared in this profile's top-level `classes:` block; substitute the class names your profile declares (`Image`, `Etd`, `Oer`, etc.) as appropriate.

Validation matrix on profile save (with the config on):

| Flipflop | Property | Result |
|---|---|---|
| off | absent | silent (the feature is not in active use) |
| off | present | warning (property is loaded but unused) |
| on | absent | error (property is required) |
| on | declared without `type: hash` | error |
| on | `available_on.class` lists no work or collection class declared in this profile | error |
| on | present, complete | silent (valid) |

When the config is **off**, an m3 profile that declares `redirects` produces a warning rather than an error. The property is dead — it won't be loaded — but Hyrax doesn't refuse to save the profile.

## Schema details (`flexible: false` mode)

In default (non-flexible) mode the schema lives in `config/metadata/redirects.yaml`:

```yaml
attributes:
  redirects:
    type: hash
    multiple: true
    form:
      display: false
    view:
      editor_only: true
      render_term: redirects_path
      render_as: redirects_label
      html_dl: true
    predicate: http://samvera.org/ns/hyku/redirects
    mappings:
      simple_dc_pmh: ~
```

The `view:` block opts the redirects field into the show-page display described below in [Displaying redirect aliases on show pages](#displaying-redirect-aliases-on-show-pages). In non-flexible mode, all view options live inside the `view:` block — that's where `Hyrax::SimpleSchemaLoader#view_definitions_for` reads them from. (Flex-true uses a different structure for `editor_only`; see the [m3 profile requirements](#m3-profile-requirements-flexible-true-mode) section.)

When the config is on, this schema is loaded and `Hyrax::Work` / `Hyrax::PcdmCollection` include it via `Hyrax::Schema(:redirects)`. The schema loader produces:

```ruby
attribute :redirects, Valkyrie::Types::Array.of(Dry::Types['hash'])
```

Each entry is a plain hash with `path` and `display_url` keys. Entries persist as JSONB on the parent resource, so sub-fields round-trip cleanly without an intermediate nested-resource schema mangling them. `Hyrax::Redirect` is retained as a thin Ruby presenter the form view consumes; non-form code (validator, indexer, sync step) reads the persisted hash directly.

When the config is off, the loader filters `redirects.yaml` out of the schema set entirely. The file is on disk but invisible to `permissive_schema_for_valkrie_adapter`, `Hyrax::Schema(:redirects)`, and any other consumer of the simple schema loader.

## Path normalization

Every redirect path in Hyrax passes through `Hyrax::RedirectPathNormalizer.call`. This is the single source of truth for "what does this path look like on disk?". Normalization rules:

1. If the input parses as a URL with a scheme and host (e.g. `https://old.example.edu/handle/12345/678`), keep only the path component.
2. Strip query strings (`?utm_source=foo`) and fragments (`#section`).
3. Ensure a leading slash (`handle/123` → `/handle/123`).
4. Strip trailing slashes (`/handle/123/` → `/handle/123`), with the exception that the bare path `/` is preserved.

The normalizer is idempotent — `normalize(normalize(x)) == normalize(x)`. Normalization happens in two distinct contexts:

**On write (resource layer).** `Hyrax::RedirectsNormalization` is included on `Hyrax::Work` and `Hyrax::PcdmCollection` and overrides `set_value` so any assignment to the `redirects` attribute — form save, console write, importer, change-set apply — normalizes each entry's path before persistence. Read-side consumers (`Hyrax::Indexers::RedirectsIndexer`, `Hyrax::Transactions::Steps::SyncRedirectPaths`) trust the persisted shape and do not re-normalize.

**On input (boundary layer).** Three boundary points canonicalize input from outside the resource before consulting the persisted state:

- `Hyrax::RedirectsFieldBehavior#redirects_attributes_populator` normalizes form entries before the form-level validator runs, so a user pasting a full URL (`https://old.example.edu/handle/123?utm=email`) is forgivingly accepted and the validator sees the canonical form.
- `Hyrax::Redirects::Middleware` normalizes the incoming request path before the `hyrax_redirect_paths` lookup, so `/foo/` and `/foo` both resolve.
- `Hyrax::RedirectsLookup` normalizes its input on construction, so callers can pass any reasonable form.

## Validation

`Hyrax::RedirectValidator` is wired into `Hyrax::Forms::ResourceForm` (and therefore both `Hyrax::Forms::PcdmObjectForm` for works and `Hyrax::Forms::PcdmCollectionForm` for collections) when `Hyrax.config.redirects_enabled?`. It runs only when the Flipflop is also on; otherwise it is a no-op.

By the time the validator sees an entry, the path has already been normalized by the form's `redirects=` setter, so the validator can assume canonical form and focus on rule violations.

The validator enforces six rules on the `redirects` attribute:

| Rule | Trigger | Error |
|---|---|---|
| Path is present | `entry.path` is blank | `redirect path can't be blank` |
| Path format | path doesn't start with `/`, contains whitespace, `?`, or `#` | `is not a valid redirect path` |
| Reserved prefix | path equals or starts with one of `Hyrax.config.reserved_redirect_prefixes` (defaults to the routes Hyrax itself reserves) | the path is reserved by the application and may not be used as an alias |
| Intra-record uniqueness | the same path appears more than once on a single record | `is listed more than once on this record` |
| Global uniqueness | the path is already in use on a different record (excluding the current record's own id) | `is already in use by another record` |
| At most one display URL | more than one entry has `display_url: true` | `at most one redirect entry may be marked as the display URL` |

### Reserved-prefix list

The reserved-prefix list lives in `Hyrax.config.reserved_redirect_prefixes`. The default covers the routes Hyrax itself reserves: `/admin`, `/api`, `/assets`, `/batch_edits`, `/batch_uploads`, `/capabilitylist`, `/catalog`, `/changelist`, `/collections`, `/concern`, `/content_blocks`, `/dashboard`, `/downloads`, `/embargoes`, `/featured_works`, `/files`, `/leases`, `/notifications`, `/pages`, `/proxies`, `/rails`, `/resourcelist`, `/uploads`, `/users`, and `/.well-known`.

Host applications with their own reserved routes (Hyku's `/single_signon`, for example) should extend the list in their initializer:

```ruby
# config/initializers/hyrax.rb
Hyrax.config do |config|
  config.reserved_redirect_prefixes += ['/single_signon']
end
```

The validator rejects any redirect path that equals one of these prefixes, or starts with one followed by `/` (so `/admin` is reserved, and `/admin/anything` is reserved, but `/administrator` would *not* be reserved by the `/admin` entry).

### Uniqueness lookup and the `hyrax_redirect_paths` table

Global uniqueness is enforced by a Postgres table, `hyrax_redirect_paths`, which has a unique B-tree index on `source_path`. The table is a derived record of every redirect path currently in use, and the unique index gives the hard guarantee that no two records can share an alias even under concurrent saves. A second non-unique index on `resource_id` supports the per-resource sync described below.

Each row carries three columns the resolver and sync step care about:

- `source_path` — the alias path. Unique.
- `target_path` — where the visitor should be sent. `NULL` means "render in place at `source_path`"; otherwise the resolver issues a 301 to the stored target.
- `display_url` — form/validator state. The row marked as the record's display URL has `display_url: true`. The sync step uses this to compute each row's `target_path`: the display row gets `target_path = NULL`, every other row on the same record gets `target_path = <display row's source_path>`. The request-time resolver does not read this column.

`Hyrax::RedirectsLookup` is the single point of truth for "is this alias taken?". It queries the table:

```sql
SELECT 1 FROM hyrax_redirect_paths WHERE source_path = ? AND resource_id <> ? LIMIT 1;
```

The validator calls `Hyrax::RedirectsLookup.taken?(path, except_id: record.id)` to give the user friendly feedback at form-submit time. If two simultaneous requests both pass validation (because both checked the table before either committed), the unique index rejects the second one at insert time and the enclosing transaction returns `Failure`.

## Selecting the display URL

The Aliases form column "Display URL" lets a user mark one alias per record as the display URL — the path the resolver treats as the institution's preferred public URL for that record. The form persists the flag onto the `display_url` column of `hyrax_redirect_paths` via the sync transaction step.

Implementation note: the form renders the column as a single radio group whose `name` is `<form>[redirects_display_url_index]` and whose values are the row indices. `Hyrax::RedirectsFieldBehavior#redirects_attributes_populator` reads that scalar and folds it onto per-row entries — the selected row gets `display_url: true`, every other row gets `display_url: false`. When the scalar is absent (the Bulkrax CSV import path), the per-row `display_url` value on each entry is honored instead, so CSV imports with explicit per-row `redirect_display_url_<n>` columns work unchanged.

The "None" radio option is the default selection and persists every row as `display_url: false`. The validator continues to enforce at-most-one display URL per record.

### Sync between `redirects` attribute and the redirects table

The redirects table is kept in sync by two `dry-transaction` steps composed into the create/update/destroy transactions:

- `Hyrax::Transactions::Steps::SyncRedirectPaths` — runs after the resource is saved (in `WorkCreate`, `WorkUpdate`, `CollectionCreate`, `CollectionUpdate`). Deletes the resource's existing rows and reinserts the current redirect set in a single DB transaction. On `ActiveRecord::RecordNotUnique` (race lost), returns `Failure([:redirect_path_collision, ...])`, which short-circuits the enclosing transaction and surfaces back to the controller. On any other `ActiveRecord::StatementInvalid` (missing table, schema drift, connection drop), logs the error and returns `Failure([:redirect_path_sync_error, ...])` rather than raising — the resource is already persisted by the time this step runs, so a soft-fail is preferable to a 500 with partial state. No-op when either the config or the Flipflop is off.
- `Hyrax::Transactions::Steps::RemoveRedirectPaths` — runs before `delete_resource` in `WorkDestroy` and `CollectionDestroy`. Clears the resource's rows so deleted resources don't leave dangling claims on redirect paths. Same `StatementInvalid` treatment as the sync step: returns `Failure([:redirect_path_remove_error, ...])` instead of raising. Gated only on the config (not the Flipflop): cleanup must happen regardless of whether the feature is currently in active use, so that an admin toggling the Flipflop off mid-deployment doesn't leave orphaned rows that could later collide with new resources after a re-enable.

Neither step does anything when the config is off, so adopters who don't enable the redirects feature pay no cost for them.

## Resolver behavior

### Middleware placement

The resolver is a Rack middleware (`Hyrax::Redirects::Middleware`), registered by the Hyrax engine via `app.middleware.use`. It runs in front of Rails routing so it can rewrite the request path before Rails sees it. No host-side `config/routes.rb` entry is required.

Adopters who layer their own middleware (CORS, auth, tenant elevators, custom 404 handlers) can position those relative to `Hyrax::Redirects::Middleware` with `config.middleware.insert_before` / `insert_after`. Multi-tenant elevators (e.g. Apartment) should run *before* the redirects middleware so the AR query in the resolver lands on the correct tenant's schema.

### What happens at request time

When both gates are open, the middleware decides the outcome of every GET/HEAD request:

- The incoming path is normalized via `Hyrax::RedirectPathNormalizer` so trailing-slash and case variations resolve consistently (a request for `/foo/` resolves the same record as `/foo`).
- Paths that can't be aliases — the bare `/` and any path under `Hyrax.config.reserved_redirect_prefixes` (which covers `/assets`, `/rails`, `/cable`, etc.) — pass straight through to Rails without a DB hit.
- `Hyrax::RedirectsLookup.find_row(path)` reads the `hyrax_redirect_paths` table. The resolver's decision tree:
  - **No row** — pass through to Rails (which produces a 404 if no other route matches).
  - **Row has `display_url: true` (the visited path *is* the display URL)** — rewrite `env['PATH_INFO']` to the resource's canonical show path and mark `env['hyrax.redirects.rewrote']`. Rails routes the rewritten path to the normal show controller; the browser address bar stays on the alias because there's no redirect.
  - **Row is a non-display alias and a sibling display row exists** — `301` to the sibling's path. The institution's preferred URL wins.
  - **Row is a non-display alias and no sibling display row exists** — `301` to the resource's canonical show path.

A companion `before_action` in `Hyrax::WorksControllerBehavior` and `Hyrax::CollectionsControllerBehavior` (`include Hyrax::RedirectToDisplayUrl`) covers the symmetric case: a visitor who lands on the bare UUID show path gets 301'd to the display URL when one is set. The `before_action` skips when `env['hyrax.redirects.rewrote']` is true so the middleware's render-in-place case doesn't bounce back to a redirect.

`Hyrax::Redirects::Resolver` is the pure service that owns the resolution logic; the middleware and the before_action both delegate to it. Postgres or Solr failures (including `SolrDocument.find` raising `Blacklight::Exceptions::RecordNotFound` for an orphan row) are logged at `warn` level and resolve to `nil`, so the request passes through to a 404 rather than producing a 5xx.

### Response headers on redirects

301 responses from this stack always carry two headers in addition to `Location:`:

- `Cache-Control: no-cache` — institutions can move the display URL flag between aliases (or clear it), and a browser-cached 301 from a prior state would defeat that. `no-cache` tells the browser to revalidate on every visit. The same header is set by the `Hyrax::RedirectToDisplayUrl` concern when the show controller issues a UUID-to-display 301.
- `Turbolinks-Location:` — Turbolinks fetches navigations via XHR and updates the browser address bar to the URL it was *asked* to visit, not the URL the redirect chain ended at. The header tells Turbolinks what to put in the address bar after the navigation completes. Set to the display URL in the redirect cases and to the originally-visited alias path in the render-in-place case.

### Caching

Resolution is wrapped in `Rails.cache.fetch` with a 60-second TTL. The cached value is the resolution struct (`{render_path: …}`, `{redirect_to: …}`, or `nil`). The cache key is path-only by default; multi-tenant host apps can override `Hyrax::Redirects::Middleware.cache_key_for` to fold a tenant token into the key:

```ruby
module Hyrax
  module RedirectsMiddlewareDecorator
    def cache_key_for(path)
      ['hyku', current_tenant_id, super].join('/')
    end
  end
end
Hyrax::Redirects::Middleware.singleton_class.prepend(Hyrax::RedirectsMiddlewareDecorator)
```

`Hyrax::RedirectCacheBuster` invalidates specific paths on resource save and destroy, so the TTL only matters for resolutions that change out-of-band (the rare case).

### Edge caches (Cloudflare, etc.)

The default Cloudflare configuration does not cache HTML or redirect responses at the edge, so the `Cache-Control: no-cache` header reaches the browser unmodified. Institutions running Cloudflare with a "Cache Everything" Page Rule on the host serving Hyrax should verify their cache rules pass redirect responses through to the origin, or tighten the header on this stack to `Cache-Control: no-store` via a middleware decorator if necessary.

## Reindexing after enabling

The resolver reads from Postgres, not Solr, so toggling the feature does not require a reindex for redirects to start working. Reindexing is only needed for the show-page **display** of registered aliases (which reads `redirects_path_tesim`): existing records need a reindex to have the field populated when the feature is first enabled, or removed when it's disabled.

```sh
bundle exec rails hyrax:solr:reindex_everything
```

## Displaying redirect aliases on show pages

When the redirects feature is enabled, the registered aliases for a work or collection appear on its show page as a list of clickable links. The display is gated by `editor_only: true` — visible to signed-in users with edit ability for the record (which includes site admins, who can edit everything). Public visitors and signed-in users without edit ability see no trace of the redirects on the show page.

The `editor_only` flag (and its sibling `admin_only`) are general flexible-metadata property visibility flags. For the full reference — including the combination rule when both flags are set and the catalog-exclusion behavior — see [Property visibility flags](flexible_metadata.md#property-visibility-flags) in the flexible metadata documentation.

The display is driven by two pieces on the redirects schema: an `editor_only` flag that gates visibility, and a `render_as: redirects_label` instruction that selects the renderer. **The two flex modes structure these differently** because their schema loaders read view options from different places.

**Non-flexible mode (`HYRAX_FLEXIBLE=false`)** — all view options live inside the `view:` block in `config/metadata/redirects.yaml`:

```yaml
view:
  editor_only: true
  render_term: redirects_path
  render_as: redirects_label
  html_dl: true
```

`Hyrax::SimpleSchemaLoader#view_definitions_for` reads `property.meta['view']` and passes the block through verbatim to the show-page rendering.

**Flexible mode (`HYRAX_FLEXIBLE=true`)** — `editor_only` is an entry in the property's `indexing:` array; the rest live inside the `view:` block:

```yaml
indexing:
  - editor_only
view:
  render_term: redirects_path
  render_as: redirects_label
  html_dl: true
```

`Hyrax::M3SchemaLoader#view_definitions_for` calls `definition.view_options`, which reads `editor_only?` (via `Hyrax::SchemaLoader::AttributeDefinition#editor_only?`, which honors both top-level `editor_only: true` and `indexing: [editor_only]`) and injects it into the view options hash. The `view:` block contents are passed through alongside.

Full snippets for each mode are shown in the [m3 profile requirements](#m3-profile-requirements-flexible-true-mode) and [Schema details](#schema-details-flexible-false-mode) sections above.

### How it works

- The redirects indexer emits `redirects_path_tesim`, used by the show-page display. The resolver itself reads from `hyrax_redirect_paths` and does not consult Solr.
- `Hyrax::SolrDocument::Metadata` declares `redirects_path` as a SolrDocument attribute bound to the `redirects_path_tesim` field. This is what makes `solr_document.redirects_path` available; the per-attribute declaration is required (Hyrax does not coerce arbitrary Solr fields into methods automatically).
- The presenter's `MissingMethodBehavior` delegates `presenter.redirects_path` to `solr_document.redirects_path`.
- The `render_term: redirects_path` view option tells the show-page partial to call `presenter.redirects_path` instead of `presenter.redirects`. The bare `redirects` attribute returns the persisted array of hashes and isn't useful for direct rendering.
- The `render_as: redirects_label` view option tells Hyrax to use the `Hyrax::Renderers::RedirectsLabelAttributeRenderer` class to render the field. Each path becomes a clickable link whose text is the full absolute URL (host + path) and whose `href` is the path alone (the browser resolves it against the current host).
- The `html_dl: true` view option matches the show page's description-list layout — the renderer emits `<dt>/<dd>` rather than the table-row `<tr>/<td>` it would default to.
- The `editor_only: true` view option makes the existing attribute-rows partial skip rendering the field entirely when the current user cannot edit the record. No section heading, no empty list — just nothing.

### Adopter customization

Adopters can override the renderer to change link styling or the displayed URL format. Subclass `Hyrax::Renderers::RedirectsLabelAttributeRenderer` and register the subclass under the same `render_as` key.

Adopters can also turn the display off without removing the redirects feature: remove the `view:` block from the schema (or the m3 profile property declaration). The redirects functionality continues to work — only the show-page display goes away.

## Migration playbook (Bulkrax)

Institutions migrating from another repository typically have hundreds to thousands of legacy URLs to preserve. Bulkrax (v9.5+) supports redirects via its `nested_attributes: true` field-mapping flag.

### CSV column format

Each redirect entry maps to two numbered columns: `redirect_path_<n>` and `redirect_display_url_<n>`. A row with two redirects, one marked as the display URL:

```csv
source_identifier,title,redirect_path_1,redirect_display_url_1,redirect_path_2,redirect_display_url_2
work-001,My Work,/handle/12345/678,true,/old/path/678,false
```

`display_url` accepts the literal string `true` or `false` (boolean strings, not `1`/`0`). At most one entry per record may be marked as the display URL.

### Field-mapping configuration

Add to the host app's Bulkrax field-mapping configuration (usually `config/initializers/default_bulkrax_mappings.rb` or a per-tenant override):

```ruby
'path'        => { from: ['redirect_path'],        object: 'redirects', nested_attributes: true },
'display_url' => { from: ['redirect_display_url'], object: 'redirects', nested_attributes: true }
```

See [field_behaviors.md](forms/field_behaviors.md#wiring-up-bulkrax-imports) for the conventions around the `nested_attributes: true` flag.

### Reserved-prefix list

The validator rejects redirect paths that match any prefix in `Hyrax.config.reserved_redirect_prefixes`. Hyrax ships a default list covering its own routes (`/admin`, `/dashboard`, `/catalog`, `/concern`, etc.); host applications extend it for their own routes (see "Validation" above). A row whose redirect path matches a reserved prefix fails validation per-row and is reported in the import errors; the rest of the import continues.

### Reindex after import

Bulkrax saves go through the same form-driven path Hyrax uses for interactive saves, so the `hyrax_redirect_paths` rows (used by the resolver) and the `redirects_path_tesim` Solr field (used by the show-page display) are both populated as part of the import.

If the redirects feature was just enabled (config + Flipflop turned on) and the show page should display registered aliases for existing records, run the reindex command from the section above to populate `redirects_path_tesim`.

### Common errors

- **"is reserved by the application and may not be used as an alias"** — the path matches a reserved prefix. Choose a different path or extend `Hyrax.config.reserved_redirect_prefixes` if the conflict is intentional.
- **"is already in use by another record"** — the path is registered as a redirect on a different work or collection. Paths are globally unique.
- **"at most one redirect entry may be marked as the display URL"** — multiple rows in the same CSV record have `redirect_display_url_<n>=true`. Only one entry per record may be marked as the display URL.
- **m3 profile validation: "redirects property is required"** (flexible mode) — the Flipflop is on but the m3 profile doesn't declare the `redirects` property. Add it per the section above.
- **m3 profile validation: "the property will be ignored"** (flexible mode, config off) — a stale `redirects` property is declared but the config is off. Either remove the property from the profile or re-enable the config.

## Disabling

To fully disable: unset `HYRAX_REDIRECTS_ENABLED` (or set `Hyrax.config.redirects_enabled = false`) and reboot. The schema is no longer loaded, the attribute is no longer included on `Hyrax::Work` / `Hyrax::PcdmCollection`, the Flipflop feature is no longer registered, and the indexer mixin is no longer included. Persisted `redirects` entries on records remain in storage (Postgres / Fedora) but are inaccessible because the attribute no longer exists on the model. Re-enabling restores access.

To disable the feature at runtime without changing the config, toggle the `:redirects` Flipflop off in the admin Flipflop UI. Multi-tenant host apps can scope this per-tenant via their Flipflop strategy chain.

### Caveats

- **`Hyrax::Redirect` (the presenter) is always defined.** The class file is loaded by Rails autoloading as soon as anything references the constant. It costs effectively nothing when unused. The "wholly absent" effect of disabling the config applies to the schema, the attribute on `Hyrax::Work` / `Hyrax::PcdmCollection`, the Flipflop, the indexer, and the m3 profile validator's enforcement — but not to the constant itself.
- **The `disabled_schemas` filter only affects `Hyrax::SimpleSchemaLoader`.** Adopters running `flexible: true` whose m3 profile contains a stale `redirects` property will still see the attribute defined on records loaded via `M3SchemaLoader` even if `Hyrax.config.redirects_enabled?` is false. The m3 profile validator emits a warning in that situation ("the property will be ignored"); follow the warning by removing the `redirects` property from the m3 profile or setting the config back on.

## For contributors

### Why a config *and* a Flipflop?

The schema include on `Hyrax::Work` and `Hyrax::PcdmCollection` runs at class-load time, often triggered by Bulkrax's initializer before the Flipflop facade is wired up. `Hyrax.config.redirects_enabled?` is queryable that early; `Flipflop.redirects?` is not. The config gates structural choices (does the attribute exist on the model? does the schema YAML get loaded?); the Flipflop gates runtime behavior at request time (do routes/controllers/indexer emit values?). Multi-tenant host apps can resolve the Flipflop per tenant; Hyrax itself doesn't have that concept.

### Calling `Flipflop.redirects?`

The `:redirects` Flipflop feature is only registered when `Hyrax.config.redirects_enabled?` is true. When the config is off, calling `Flipflop.redirects?` raises `NoMethodError`. Any new code that consults the feature flag must short-circuit on the config first:

```ruby
Hyrax.config.redirects_enabled? && Flipflop.redirects?
```

Alternatively, gate the inclusion of the calling code itself on `Hyrax.config.redirects_enabled?` (as the indexer mixin does in `Hyrax::Indexers::PcdmObjectIndexer` and `Hyrax::Indexers::PcdmCollectionIndexer`); then the body can check `Flipflop.redirects?` alone because it only runs when the feature is registered.

## See also

- `documentation/flexible_metadata.md` — m3 profile fundamentals and how the redirects feature interacts with flexible metadata.
- `documentation/forms/field_behaviors.md` — the Field Behavior pattern used by `Hyrax::RedirectsFieldBehavior` to wire the form's nested-attribute property.
- `Hyrax::Redirect` (`app/models/hyrax/redirect.rb`) — thin Ruby presenter for a single redirect entry; used on the form's render path.
- `Hyrax::RedirectsFieldBehavior` (`app/forms/concerns/hyrax/redirects_field_behavior.rb`) — form-side wiring for the `redirects` and `redirects_attributes` properties: loads the persisted property from `config/metadata/redirects.yaml` via `Hyrax::FormFields(:redirects)`, and owns the populator/prepopulator and the `deserialize!` strip for the nested-attributes payload.
- `Hyrax::Indexers::RedirectsIndexer` (`app/indexers/hyrax/indexers/redirects_indexer.rb`) — the indexer mixin. Emits `redirects_path_tesim` for show-page display.
- `Hyrax::SolrDocument::Metadata` (`app/models/concerns/hyrax/solr_document/metadata.rb`) — declares the `redirects_path` attribute on `SolrDocument`, bound to the `redirects_path_tesim` Solr field. This is what makes `solr_document.redirects_path` (and therefore `presenter.redirects_path` via `MissingMethodBehavior`) available to the show-page renderer.
- `Hyrax::Renderers::RedirectsLabelAttributeRenderer` (`app/renderers/hyrax/renderers/redirects_label_attribute_renderer.rb`) — show-page renderer that turns each redirect path into a clickable link.
- `Hyrax::Redirects::Middleware` (`lib/hyrax/redirects/middleware.rb`) — Rack middleware that resolves alias paths at request time. Renders in place for display URLs, 301s for non-display aliases.
- `Hyrax::Redirects::Resolver` (`app/services/hyrax/redirects/resolver.rb`) — the pure service used by the middleware and by `Hyrax::RedirectToDisplayUrl` to compute the resolution for a path.
- `Hyrax::RedirectToDisplayUrl` (`app/controllers/concerns/hyrax/redirect_to_display_url.rb`) — included into the work and collection show controllers; 301s UUID-style show requests to the record's display URL when one is set.
- `Hyrax::FlexibleSchemaValidators::RedirectsValidator` (`app/services/hyrax/flexible_schema_validators/redirects_validator.rb`) — the m3 profile validator.
- `Hyrax::RedirectValidator` (`app/validators/hyrax/redirect_validator.rb`) — the form-level entry validator.
- `Hyrax::RedirectPathNormalizer` (`app/services/hyrax/redirect_path_normalizer.rb`) — canonical-form normalization for redirect paths.
- `Hyrax::RedirectsLookup` (`app/services/hyrax/redirects_lookup.rb`) — Postgres reads against `hyrax_redirect_paths`: uniqueness checks for the validator and `find_row`/`display_path_for` for the resolver.
- `Hyrax::PermalinkHelper#canonical_url_for` (`app/helpers/hyrax/permalink_helper.rb`) — helper used by show views to emit `<link rel="canonical">` pointing at the display URL when one is set.
- `Hyrax::RedirectPath` (`app/models/hyrax/redirect_path.rb`) — ActiveRecord model for the `hyrax_redirect_paths` table.
- `Hyrax::Transactions::Steps::SyncRedirectPaths` and `Hyrax::Transactions::Steps::RemoveRedirectPaths` (`lib/hyrax/transactions/steps/`) — the transaction steps that keep the redirects table in sync with each resource's `redirects` attribute.
