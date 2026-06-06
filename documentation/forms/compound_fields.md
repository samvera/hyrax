# Compound (hierarchical) metadata fields

A **compound field** is a metadata attribute whose value is a list of entries,
where each entry is itself a small set of named **sub-properties**. It is the
Hyrax foundation for hierarchical metadata: contributors with a name, role and
identifier; dates with a value and type; funding references with a funder name
and award number; and so on.

A compound is declared entirely in the schema (a `config/metadata/*.yaml`
schema under `HYRAX_FLEXIBLE=false`, or the m3 profile under
`HYRAX_FLEXIBLE=true`). No per-compound Ruby or ERB is required: the generic
form input, populator, and indexer all read the declaration from the schema
and behave identically in both flex modes.

## Declaring a compound

A compound is a `type: hash, multiple: true` attribute that also carries a
`subproperties:` map:

```yaml
contributors:
  type: hash
  multiple: true
  predicate: https://prvoices.org/terms/contributor
  subproperties:
    given_name:
      type: string
      index_keys: [contributors_given_name_sim, contributors_given_name_tesim]
    family_name:
      type: string
      index_keys: [contributors_family_name_sim, contributors_family_name_tesim]
    name_type:       { type: controlled, authority: name_type }
    role_label:      { type: controlled, authority: contributor_role }
    name_identifier:
      type: string
      index_keys: [contributors_name_identifier_ssim]
    affiliation:     { type: string }   # display-only (no index_keys)
  groups:
    - { label: Identity, cols: 4, fields: [given_name, family_name, name_type] }
    - { label: Role,     cols: 4, fields: [role_label, name_identifier, affiliation] }
```

In the m3 profile the same declaration uses `data_type: array`, `type: hash`,
and `available_on: class:` to scope the property, with the identical
`subproperties:` / `groups:` keys; sub-property index targets are declared with
`indexing:` (the flexible-mode spelling of `index_keys:`).

> **Flexible mode:** the active schema is the `Hyrax::FlexibleSchema` row in the
> database, seeded from the m3 profile — not the YAML file directly. After
> editing the m3 profile, reseed the flexible schema (`Hyrax::FlexibleSchema`
> import) and restart the web process so the running app picks up both the new
> schema and any Ruby changes. The schema is applied to each resource's
> singleton class at load time, so a stale running process serves the old
> attribute set even when the profile YAML is current.

### `subproperties:`

An ordered map of `sub_property_key => { type:, ... }`. Supported `type:` values:

| `type:`      | Renders as          | Notes |
|--------------|---------------------|-------|
| `string`     | text input          | The default when `type:` is omitted. |
| `url`        | url input → auto-linked on show | The stored value is rendered as a clickable `<a href>` on show pages (matching the scalar `render_as: external_link` behavior). |
| `work_or_url` | select2 typeahead → linked on show | Searches internal works (via the `compound_works` QA authority, backed by `Hyrax::CompoundWorkPickerBuilder`) **or** accepts a typed external URL. The stored value is a work id or a URL; on show, a work id links to the work's show page with its title (resolved by `Hyrax::CompoundWorkResolver`), a URL is auto-linked. |
| `controlled` | `<select>` dropdown | Options come from either an inline `values:` list or a QA local authority named by `authority:` (see below). The row's stored value is preserved even if it is no longer offered, matching the `include_current_value` convention of the ordinary controlled-field partials. |

A `controlled` sub-property sources its options one of two ways:

```yaml
subproperties:
  # (a) inline list — no authority file needed
  agent_role:
    type: controlled
    values: [Author, Editor, Contributor]
  # (a') inline list with distinct id and label
  status:
    type: controlled
    values:
      - { id: pub, label: Published }
      - { id: dft, label: Draft }
  # (b) an existing QA local authority (config/authorities/<name>.yml)
  identifier_type:
    type: controlled
    authority: identifier_type
```

Inline `values:` is convenient for small, stable lists and keeps the whole
declaration in one file. `authority:` reuses an existing QA local authority —
the same `config/authorities/*.yml` files ordinary controlled fields use. When
both are given, `values:` wins. Authority options are read through
`Hyrax::TolerantSelectService`, so an authority file that omits the `active:`
key behaves the same as it does for ordinary fields (terms default to active).

A `work_or_url` sub-property's work search is broader than the stock "my works"
picker: `Hyrax::CompoundWorkPickerBuilder` matches a typed term against any
indexed query field **or** a partial/prefix title (so "jour" matches "Journal
of …"), restricted to works. It subclasses `Hyrax::SearchBuilder`, so the
catalog's read-permission filtering is retained — a user only sees works they
can read. The picker is mounted as the `compound_works` QA authority at
`/authorities/search/compound_works`.

`db_table` (a typeahead backed by an ActiveRecord lookup table, with
add-new) and `geocode` (a Geonames/coordinate lookup, like `based_near`) are
planned additional sub-property types; the form's row partial has an explicit
extension point for them.

### `groups:` (optional)

Visual clustering of sub-properties within each entry's card. Each group is
`{ label:, cols:, fields: [...] }`, where `cols` is the Bootstrap column width
(out of 12) for each field in the group. When omitted, all sub-properties render in
a single unlabeled group.

### Indexing sub-properties (`index_keys:` / `indexing:`)

Indexing is declared **per sub-property**, exactly as for scalar fields: list the
literal Solr field names the sub-property's value should be written to, under
`index_keys:` (non-flexible mode) or `indexing:` (flexible mode). The Solr
suffix on each name chooses the behavior — `_tesim` (stored + searchable,
multi-valued), `_sim` (facetable, not stored), `_ssim` (stored + facetable),
etc. — the same conventions scalar fields use. The author picks both the field
names and the suffixes.

A sub-property with no `index_keys:`/`indexing:` is **not** written to a Solr field
of its own; it can still appear on the show page (see below). As with scalar
fields, the non-field control tokens (`facetable`, `stored_searchable`,
`admin_only`, `editor_only`) are filtered out if present.

Indexing a sub-property makes it **searchable/facetable** in Solr; it does **not**
make it appear as a column on the catalog/search-results page. The catalog
renders only the fields explicitly registered with Blacklight
(`config.add_index_field`) — compound sub-properties are not registered by default.
To show a sub-property in search results, register its Solr field name in your
`CatalogController` (e.g.
`config.add_index_field 'agent_name_tesim', label: 'Agent'`). The show page and
edit form render compounds regardless.

### `display:` (optional, default true)

Controls whether a sub-property is included in the `<compound>_json_ss` blob that
the show page renders from. Combined with indexing, each sub-property can be:

- **display + searchable** — has `index_keys:` and `display` not false
- **display-only** — no `index_keys:` (renders on show, not separately searchable)
- **searchable-only** — has `index_keys:` and `display: false` (indexed, hidden on show)
- **neither** — no `index_keys:` and `display: false`

### `required:` (optional, default false)

Marks a sub-property as required within each populated row, or — when set on the
compound itself — marks the whole compound as required. See
[Required sub-properties](#required-sub-properties) below.

## Persisted shape

A compound persists as an array of plain string-keyed hashes — exactly the
keys declared in `subproperties:`:

```ruby
work.contributors
# => [{ "given_name" => "Ada", "family_name" => "Lovelace", "role_label" => "author" },
#     { "given_name" => "Alan", "family_name" => "Turing",  "role_label" => "author" }]
```

This shape round-trips cleanly through Postgres JSONB in both flex modes. (Use
this plain-hash shape rather than nesting a `Valkyrie::Resource`; nested
resources round-trip poorly and lack form-layer support — see
[`field_behaviors.md`](field_behaviors.md).)

## What the foundation provides

Adding a compound to the schema is enough to get all of the following, with no
per-compound code:

- **Form rendering** — `Hyrax::Forms::ResourceForm#compound_terms` lists the
  compounds, and the work form renders each via the
  `hyrax/compounds/_compound_section` partials (a repeatable card stack with
  add/remove-row controls). The add/remove client behavior is the engine asset
  `app/assets/javascripts/hyrax/compound_metadata.js` (required via
  `hyrax.js`). Compounds are excluded from `primary_terms` / `secondary_terms`
  so they are not also rendered as scalar inputs.
- **Form → storage conversion** — `Hyrax::CompoundFieldBehavior` registers a
  virtual `<name>_attributes` property per compound and a shared populator that
  builds the persisted array, dropping `_destroy` and all-blank rows and
  keeping only declared sub-property keys.
- **Read-path defense** — `Hyrax::CompoundNormalization`, included on the
  resource, guards against Valkyrie's single-element-array key-splay quirk on
  reload.
- **Indexing** — `Hyrax::Indexers::CompoundIndexer`, included on the indexer,
  writes each sub-property's value to the Solr field names it declares
  (`index_keys:`/`indexing:`) and stores the displayable sub-properties as a
  `<compound>_json_ss` blob for the show page.

A resource and its indexer opt in with one include each:

```ruby
class GenericWorkResource < Hyrax::Work
  include Hyrax::Schema(:generic_work_resource)
  include Hyrax::CompoundNormalization
end

class GenericWorkResourceIndexer < Hyrax::ValkyrieWorkIndexer
  include Hyrax::Indexer(:generic_work_resource)
  include Hyrax::Indexers::CompoundIndexer
end
```

## Sample compounds shipped with Hyrax

Hyrax ships sample compounds on **works and collections** by default,
demonstrating the supported sub-property types:

- **`participants`** — `title`, `participant_name`, and a controlled
  `participant_role` (inline `values:`). A person or organization associated
  with the work or collection.
- **`identifiers`** — an open-entry `identifier` plus a controlled
  `identifier_type` (inline `values:`).
- **`compound_rights`** — controlled `rights_statement` and `license` backed by
  *existing* QA local authorities (`authority:`), plus an open `rights_notes`.
- **`relationships`** — a `work_or_url` `related_item` (search an internal work
  or enter an external URL; linked on show) plus a controlled
  `relationship_type`.

They are declared in `config/metadata/compound_metadata.yaml` (non-flexible
mode) and in the default m3 profile (`config/metadata_profiles/m3_profile.yaml`,
flexible mode, `available_on` both `Hyrax::Work` and the collection class).
The engine base `Hyrax::Work` and `Hyrax::PcdmCollection` include them, and the
base work and collection indexers flatten them, when
`Hyrax.config.compound_metadata_enabled?` is true (the default; set
`compound_metadata_enabled = false`, or `HYRAX_COMPOUND_METADATA_ENABLED=false`,
to omit them). Applications can add their own compounds the same way and remove
or override the samples.

## Show-page rendering

Because the show page renders from Solr (not the live resource), the indexer
also stores each compound's ordered rows (limited to sub-properties with `display:`
not false) as a single JSON field (`<compound>_json_ss`). The SolrDocument
defines a `<compound>` reader for each such blob it carries — so an
application's own compounds work with no per-document declaration — that
parses it back into an array of hashes, and the generic
`Hyrax::Renderers::CompoundAttributeRenderer` (selected by `view: render_as:
compound`) renders each entry's populated sub-properties as a small definition
list. Works render compounds through the standard `attribute_to_html` /
`render_as` path; collections render them through the same shared renderer,
invoked from the collection show view for terms the presenter reports as
compounds. Sub-property labels come from the `hyrax.compound_fields.<compound>.<subproperty>`
i18n keys (humanized fallback).

For a `controlled` sub-property, the show page displays the authority/value-list
**term**, not the stored id — `Hyrax::CompoundSubpropertyLabeler` resolves the id
through the sub-property's inline `values:` list or its QA `authority:` (falling
back to the id when no term matches), the same way scalar controlled fields
display their term.

### Inline vs. card display (`view: { display: card }`)

By default a compound renders **inline** in the metadata list, like any other
attribute. Declaring `view: { display: card }` on the compound instead renders
it as its **own titled card** on the show page — matching the Relationships and
Items cards — for compounds that read better as a standalone block:

```yaml
relationships:
  type: hash
  multiple: true
  view:
    render_as: compound
    display: card
  subproperties:
    related_item:      { type: work_or_url }
    relationship_type: { type: controlled, authority: relationship_type }
```

`Hyrax::CompoundSchema` reports each compound's `display_mode` (`:inline` or
`:card`); `card_compound_names` lists the card compounds. The view helper
`render_compound_cards(presenter)` renders every card compound that has a value:

- On a **work** show page, the cards render above the Relationships and Items
  cards.
- On a **collection** show page, the cards render after the search-within bar
  and before the works list.

Inline compounds are still listed by the presenter's `terms`; card compounds are
excluded from the inline list (`inline_compound_names`) so they appear only as
their card. A collection presenter delegates the card compound's reader to its
SolrDocument so the same `attribute_to_html(:<compound>, render_as: :compound)`
path resolves on a collection as on a work.

## Profile validation (flexible mode)

In flexible mode, `Hyrax::FlexibleSchemaValidators::CompoundValidator` checks
compound declarations when an m3 profile is saved/uploaded, so a
misconfiguration fails with a clear message instead of producing dead Solr
fields or unrenderable values. It enforces: `subproperties:` is a mapping; each
sub-property config is a mapping; a `type: controlled` sub-property declares an
option source (`authority:` or `values:`); and the compound does **not** carry
a top-level `indexing:` (indexing is declared per sub-property — a top-level
`indexing:` would point the catalog at a `<compound>_tesim` field the indexer
never writes).

## Required sub-properties

A compound declares requiredness at two levels:

- **Sub-property level** — `required: true` on a sub-property means every populated
  row must fill it. A row that fills some-but-not-all of its required
  sub-properties blocks save (e.g. a relationship row with a related item but no
  type).
- **Compound level** — `required: true` on the compound (or, in flexible mode,
  a minimum cardinality of 1) means at least one row must be present to save.
  An optional compound with no rows is always valid; the sub-property rules only
  apply to rows the user actually adds.

```yaml
relationships:
  type: hash
  multiple: true
  required: true            # the work must have at least one relationship
  subproperties:
    related_item:      { type: work_or_url, required: true }
    relationship_type: { type: controlled, authority: relationship_type, required: true }
    note:              { type: string }   # optional
```

Required sub-properties and required compounds render a `*` marker on the form
label. On save, `Hyrax::CompoundEntryValidator` (wired on the resource form,
gated by `compound_metadata_enabled?`) adds one error per compound, keyed on the
compound's attribute name, so the failure is reported against that field. The
rules are the same in both flex modes.

The decision logic lives in `Hyrax::CompoundEntryValidation`, a plain object
decoupled from ActiveModel and Reform — given a compound's definition and its
rows it returns the violations. That seam keeps the rules reusable (e.g. a
future Bulkrax-side check) and unit-testable without a form. Note: Bulkrax
import does not currently run this validation, so a required sub-property can be
left empty by an import.

## Validation

Sub-property format and controlled-vocabulary correctness belong in an
`ActiveModel::EachValidator` wired through the form's `validation` block — not
in the populator, whose only job is shape conversion. This mirrors the
`field_behaviors.md` guidance.

## Bulkrax

A compound round-trips through Bulkrax import and export with no additional
code, using Bulkrax's declarative `nested_attributes: true` field-mapping flag
(Bulkrax v9.4.3+). Declare the flag on every sibling mapping that shares the
compound's `object:` value, and keep each mapping key equal to the sub-property
key. See `field_behaviors.md` for the column conventions. Note: Bulkrax's
controlled-URI sanitization does not currently descend into compound
sub-properties.
