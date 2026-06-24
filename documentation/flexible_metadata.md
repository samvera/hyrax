# Flexible Metadata

Hyrax v5.3 and later includes flexible metadata functionality that allows administrators to configure metadata schemas through the UI using M3 (Machine-readable Metadata Modeling) profiles. This feature is **disabled by default** and must be explicitly enabled.

### Key Features

- **UI-based Configuration**: Admins can define and manage metadata fields through the Hyku admin dashboard
- **Multi-tenant Support**: Full support for Hyku's multi-tenant architecture
- **Version Control**: Metadata profiles can be versioned, imported, and exported
- **Work Type Customization**: Control over field labels, required status, searchability, and more per Work Type
- **Reduced Developer Dependency**: Basic metadata changes no longer require developer involvement

## Configuration

Setting the Hyrax configuration option `flexible` will allow the M3 profile loader and other flexible metadata elements to appear in the UI. It does not make any of the models themselves use flexible metadata.

There are two ways to make models flexible:

- Setting the Hyrax configuration option `flexible_classes` will toggle flexible metadata on for those classes automatically in Hyrax.
- Manually adding `acts_as_flexible` to any model class that inherits from `Hyrax::Resource`

You may choose whether to include the basic metadata always or to make them part of the flexible metadata profile. If you wish to use the default provided M3 profile, you must set `admin_set_include_metadata`, `collection_include_metadata`, `file_set_include_metadata`, or `work_include_metadata` to `false` so that basic metadata can instead be read from the flexible metadata profile. You can also set all of these from the ENV by setting the `HYRAX_DISABLE_INCLUDE_METADATA` environment variable to `true`.


### Koppie Flexible
HYRAX_FLEXIBLE=true
HYRAX_FLEXIBLE_CLASSES=Hyrax::AdministrativeSet,CollectionResource,FileSet,GenericWork,Monograph
HYRAX_DISABLE_INCLUDE_METADATA=true

### Dassie Flexible
export HYRAX_FLEXIBLE=true
export HYRAX_FLEXIBLE_CLASSES=AdminSetResource,CollectionResource,Hyrax::FileSet,GenericWorkResource,Monograph
export HYRAX_DISABLE_INCLUDE_METADATA=true
export VALKYRIE_TRANSITION=true # this is needed to properly load Valkyrie models in Hyrax config and Bulkrax

## Documentation

For comprehensive information about flexible metadata, including:

- How to create and manage metadata profiles
- M3 profile structure and syntax
- Work Type configuration
- Schema versioning
- User guide for administrators

See the official [Flexible Metadata Documentation](https://samvera.atlassian.net/wiki/spaces/hyraxdocs/pages/3382542341/Flexible+Metadata) on the Samvera Confluence.

## Property visibility flags

A property declaration can mark a field as restricted so it is hidden from public visitors. Two flags are supported, each enforcing an independent restriction:

- **`admin_only`** — the field renders on show pages only when the current user has the admin role.
- **`editor_only`** — the field renders on show pages only when the current user has CanCan `:edit` ability on the record being viewed. Admins satisfy this by virtue of edit permission on everything, so an `editor_only` field is visible to admins as well as to per-record editors.

Each flag is an independent restrictor. When both are set on the same field, both must pass: the field renders only for users who are admin *and* an editor of the record.

### Catalog behavior

Restricted fields (declared with either `admin_only` or `editor_only`) are **not exposed through the Blacklight catalog at all** — no search-results column, no facet, and not added to free-text search. Hiding occurs at field registration time, not at render time, so a restricted field's data does not appear in catalog responses for any user.

Visibility for restricted fields is enforced on show pages by the `field_visible?` view helper.

### `view:`-driven visibility (show page and catalog separately)

Beyond the role flags, a property's `view:` block controls show-page and catalog visibility independently:

- **Show page is opt-in via `view:`.** A property renders on the show page only when it declares a meaningful `view:` block (e.g. `html_dl: true`); a property with no `view:` block is not enrolled in show-page rendering at all (the `display_label` / `admin_only` / `editor_only` keys alone don't count). Within a rendered field, `view: { show_page: false }` hides it from the show page for everyone (the value is still stored and indexed).
- **`view: { search_results: false }`** drops the property's column from catalog search results, while leaving it on the show page. It suppresses only the search-results column — the property can still be **facetable** (declare `facetable` in `indexing:`).

These combine with the role flags: `admin_only` / `editor_only` remove a property from the catalog entirely (column *and* facet) at registration time, whereas `search_results: false` removes only the column.

### Declaring the flags

In a YAML schema (HYRAX_FLEXIBLE=false), declare the flag at the top level of the property:

```yaml
admin_note:
  type: string
  multiple: false
  predicate: http://schema.org/positiveNotes
  editor_only: true
  view:
    html_dl: true
```

In an m3 profile (HYRAX_FLEXIBLE=true), declare the flag as a string entry in the property's `indexing:` array, alongside index keys and the standard `stored_searchable` / `facetable` flags:

```yaml
admin_note:
  available_on:
    class:
      - GenericWork
  display_label:
    default: Admin Note
  indexing:
    - admin_note_tesim
    - stored_searchable
    - editor_only
  property_uri: http://schema.org/positiveNotes
  range: http://www.w3.org/2001/XMLSchema#string
```

Use `admin_only` in place of `editor_only` to restrict visibility to admins only.

## HTML fields in catalog search results

A field declared `view: { render_as: html }` stores HTML markup. Without a render helper, Blacklight escapes the value and dumps raw tags into the search-results column. `Hyrax::HyraxHelperBehavior#render_html_index_value` instead renders a clean, truncated plain-text snippet (tags → spaces, stripped, entities decoded; default 230 characters).

In flexible mode `Hyrax::FlexibleCatalogBehavior` wires this helper automatically from `render_as: html`; in non-flexible mode declare it on the field, e.g. `config.add_index_field 'context_narrative_tesim', helper_method: :render_html_index_value`.

The snippet length is author-declarable with `view: { search_results_truncate: N }` (`false` shows the full snippet; default 230). In non-flexible mode pass it as a field option (`search_results_truncate: N`). `search_results_truncate` only applies to `render_as: html` fields; declaring it without `render_as: html` raises a validation warning (it would otherwise be a silent no-op).

```yaml
# HYRAX_FLEXIBLE=true (m3 profile)
context_narrative:
  available_on:
    class:
      - GenericWorkResource
  data_type: string
  indexing:
    - context_narrative_tesim
  property_uri: http://purl.org/dc/terms/description
  view:
    render_as: html              # render the stored markup as HTML (sanitized) on the show page
    search_results_truncate: 300 # optional; catalog snippet length, `false` to disable (default 230)
```

## Related features

- **Compound (hierarchical) metadata**: an m3 profile (or YAML schema) can declare a `type: hash` property whose members are separate properties naming it via `available_on: { properties: [...] }` — repeatable groups of sub-fields such as `contributors`, `titles`, or `relationships`. Member sub-property types include `string`, `controlled`, `url`, `work_or_url`, and `linked_record` (a reference to a row in a database table, with an inline search-or-create picker). See [`documentation/compound_fields.md`](compound_fields.md) for declaring compounds, the supported sub-property types, indexing, and show-page rendering.
- **URL Redirects** (`HYRAX_REDIRECTS_ENABLED`): when enabled, the redirects feature requires a `redirects` property in the m3 profile (when also Flipflop-enabled per tenant). See [`documentation/redirects.md`](redirects.md) for the full schema and gating model.
- **Copy permalink button** (Flipflop `copy_permalink_button`): a show-page button that copies the record's canonical UUID-based URL. See [`documentation/copy_permalink.md`](copy_permalink.md).

## Flexible TODOs
* add the schema loader
* add the flexible schema model
* make koppie flexible with includes
  * does collection resource get the right schema include?
  * resource form based near helper removed... do we need it?
* document steps to make existing app flexible

- generator options to add flexibility
  - app generator should have a flag to turn flexible metadata on or off
    - that flag should set the `flexible` configuration option to `true` or `false`
    - that flag should set the `flexible_classes` correctly
    - that flag should set the `admin_set_include_metadata`, `collection_include_metadata`, `file_set_include_metadata`, or `work_include_metadata` configuration options to `false` or `true`
