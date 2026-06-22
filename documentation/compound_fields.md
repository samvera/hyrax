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

## When to use a compound vs. a Field Behavior

A compound is the **default** for any field whose entries are a hash of named
sub-properties (each an open-entry string or a controlled-vocabulary lookup):
declare it in the schema and the generic form, populator, indexer, and renderer
do the rest, with no per-field Ruby or ERB.

Reach for a hand-written [Field Behavior](field_behaviors.md) only for the
narrow cases the generic path does not cover:

- **A single value per entry** rather than a hash of sub-properties — e.g. a
  controlled-vocabulary URI string wrapped in a presenter for the form
  (`Hyrax::BasedNearFieldBehavior`).
- **Bespoke per-field behavior** — a radio-group selection, write-time value
  normalization, global-uniqueness validation against a separate table, or
  feature gating (`Hyrax::RedirectsFieldBehavior`).

`Hyrax::CompoundFieldBehavior` is itself a Field Behavior — the generic,
schema-driven one — so the two mechanisms share the same Reform contract
(documented in [`field_behaviors.md`](field_behaviors.md)); a compound is the
case where that contract is satisfied entirely from the schema.

## Declaring a compound

A compound is a `type: hash, multiple: true` **parent** property. Its members
are declared as separate top-level properties that name the parent compound(s)
they belong to via `available_on: { properties: [<parent>] }` — the same
`available_on` block a standalone property uses to declare its class scope, but
with a `properties:` list (the parent compounds) instead of `class:`. Every
property key is globally unique, so subproperty keys are conventionally prefixed;
the field's key *inside* the compound is its `name:` (falling back to the key):

```yaml
contributors:
  type: hash
  multiple: true
  predicate: https://prvoices.org/terms/contributor
  # Optional group metadata (label only) for subproperties that name a `group:`.
  groups:
    identity: { label: Identity }
    role:     { label: Role }

contributor_given_name:
  type: string
  name: given_name                 # key inside the compound row
  available_on: { properties: [contributors] }
  group: identity
  form: { cols: 4 }
  # no indexing declared -> derived: contributors_given_name_sim + _tesim
contributor_family_name:
  type: string
  name: family_name
  available_on: { properties: [contributors] }
  group: identity
  form: { cols: 4 }
contributor_name_type:
  type: controlled                 # derived facet-only: contributors_name_type_sim
  name: name_type
  available_on: { properties: [contributors] }
  group: identity
  authority: name_type
contributor_role_label:
  type: controlled
  name: role
  available_on: { properties: [contributors] }
  group: role
  authority: contributor_role
contributor_affiliation:
  type: string
  name: affiliation
  available_on: { properties: [contributors] }
  indexing: false                  # display-only: shown on the page, no Solr field
  group: role
```

`available_on: { properties: [...] }` is a declaration hint only: a subproperty
does **not** become a standalone resource attribute (no accessor, Solr index
rule, or RDF predicate of its own). Its data lives only as a key inside the
parent compound's row hashes; the schema loaders fold the subproperties into the
parent's type metadata for the form, indexer, and renderer to read.

**A subproperty may belong to more than one compound** — list several parents
(`available_on: { properties: [contributors, participants] }`) and the same
definition is folded into each. Combined with `name:`, this lets a shared field
surface under the same in-compound key (e.g. `title`) in several compounds
without repeating its full definition. A subproperty inherits its class scope
(the works/collections it is available on) from the union of its parents'
`available_on: { class: }`.

A reused subproperty is indexed **per parent**: its Solr fields are derived as
`<compound>_<name>_<suffix>`, so the same `title` folded into `participants` and
`relationships` writes to `participants_title_*` and `relationships_title_*` —
distinct fields, no collision, no hand-written `indexing:`. (Declaring an
explicit `index_keys:`/`indexing:` on a reused subproperty is therefore a
mistake: one literal field name would be written from every parent and collide.
See [Indexing](#indexing-sub-properties-derived-by-default).)

Ordering is document order: subproperties render in the order they are declared,
and groups in the order their first member appears.

The m3 profile uses the same shape with `data_type: array`, `type: hash` on the
parent. Where an explicit index override is needed, the flexible-mode spelling
of `index_keys:` is `indexing:` (see [Indexing](#indexing-sub-properties-derived-by-default)).

> **Flexible mode:** the active schema is the `Hyrax::FlexibleSchema` row in the
> database, seeded from the m3 profile — not the YAML file directly. After
> editing the m3 profile, reseed the flexible schema (`Hyrax::FlexibleSchema`
> import) and restart the web process so the running app picks up both the new
> schema and any Ruby changes. The schema is applied to each resource's
> singleton class at load time, so a stale running process serves the old
> attribute set even when the profile YAML is current.

### Subproperties

Each subproperty is a top-level property declaring `available_on: { properties:
[<parent>] }`, its data `type:`, and — under `form:` — its layout: `cols` (Bootstrap column
width out of 12; 4 fits three across a row, 6 two across, 12 full width) and an
optional `as` widget override (SimpleForm's `as:`, e.g. `as: text` for a
textarea). Supported `type:` values:

| `type:`      | Renders as          | Notes |
|--------------|---------------------|-------|
| `string`     | text input          | The default when `type:` is omitted. |
| `url`        | url input → auto-linked on show | The stored value is rendered as a clickable `<a href>` on show pages (matching the scalar `render_as: external_link` behavior). |
| `work_or_url` | select2 typeahead → linked on show | Searches internal works (via the `compound_works` QA authority, backed by `Hyrax::CompoundWorkPickerBuilder`) **or** accepts a typed external URL. The stored value is a work id or a URL; on show, a work id links to the work's show page with its title (resolved by `Hyrax::CompoundWorkResolver`), a URL is auto-linked. |
| `linked_record` | select2 typeahead → linked on show | A reference to a row in a database table (a person, organization, funder, place, …). The stored value is the row id; the picker searches that table and, optionally, lets a cataloger add a new record inline. On show, the id links to the record using the resolved label. The table and its procs are registered by the host application — see [`linked_record` sub-properties](#linked_record-sub-properties) below. |
| `controlled` | `<select>` dropdown | Options come from either an inline `values:` list or a QA local authority named by `authority:` (see below). The row's stored value is preserved even if it is no longer offered, matching the `include_current_value` convention of the ordinary controlled-field partials. |

A `controlled` sub-property sources its options one of two ways:

```yaml
# (a) inline list — no authority file needed
participant_role:
  type: controlled
  available_on: { properties: [participants] }
  values: [Author, Editor, Contributor]
# (a') inline list with distinct id and label
participant_status:
  type: controlled
  available_on: { properties: [participants] }
  values:
    - { id: pub, label: Published }
    - { id: dft, label: Draft }
# (b) an existing QA local authority (config/authorities/<name>.yml)
identifier_type:
  type: controlled
  available_on: { properties: [identifiers] }
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

`geocode` (a Geonames/coordinate lookup) is a planned additional sub-property
type; the form's row partial has an explicit extension point for it. `geocode`
generalizes the existing single-value controlled-URI location field — see
`Hyrax::BasedNearFieldBehavior` and
[`field_behaviors.md`](field_behaviors.md), which `geocode` is intended to
replace once it lands.

### `linked_record` sub-properties

A `linked_record` sub-property's value is a reference to a row in a database
table — a person, organization, funder, place, or any other entity you want to
record once and cite from many works, rather than retyping the same name on each
work. The stored value is the row id; on show pages it renders as a link to that
record using a resolved label.

Hyrax provides the **mechanism**; the host application provides the **table**.
You register a *source* — a name plus the procs that map between a stored id and
a record — with `Hyrax::CompoundLinkedRecordResolver`, and name that source in
the sub-property's `authority:` key. (Hyrax ships no person/organization table
itself, so the examples below assume an application-supplied `Person` model.)

```ruby
# config/initializers/linked_records.rb
Rails.application.config.to_prepare do
  Hyrax::CompoundLinkedRecordResolver.register(
    :people,
    finder: ->(id)    { Person.find_by(id:) },
    label:  ->(person) { person.display_name },
    path:   ->(person) { Rails.application.routes.url_helpers.person_path(person) },
    # optional — enables the picker autocomplete:
    search: ->(q) { Person.where('display_name ILIKE ?', "%#{q}%").limit(20)
                          .map { |p| { id: p.id.to_s, label: p.display_name, value: p.id.to_s } } },
    # optional — enables inline "add new" (lookup-or-create):
    create: ->(attrs) { Person.create(attrs.slice(:display_name, :orcid)) }
  )
end
```

**What the table needs.** The source can wrap any object the four procs can
operate on — typically an `ActiveRecord` model, but nothing about the type is
prescribed. The only contract is what the procs imply:

- a stable identifier the `finder` can look up by and that is safe to persist as
  a string (an integer or UUID primary key is fine — it is stored as its string
  form);
- a human-readable label (whatever `label:` / `view: { label_field: }` returns);
- any other fields the `path:`, `search:`, or `create:` procs reference.

There is **no base class to inherit, no required column names, no migration or
schema Hyrax imposes, and no per-source authority or controller class to write** —
the generic authority and create endpoint (below) serve every source. Registering
the source is the whole integration.

```yaml
# the sub-property names the registered source via `authority:`
creator_ref:
  type: linked_record
  name: creator
  available_on: { properties: [creators] }
  authority: people          # the registered source name
  view:
    label_field: display_name # which record field supplies the show-page link text
  # optional inline lookup-or-create form (only when `create:` is registered):
  creatable: true
  create_fields:
    - { name: display_name, as: string, required: true }
    - { name: orcid, as: string }
    - { name: kind, as: select, values: [person, organization] }
    # a repeatable scalar -> the proc receives an Array of strings:
    - { name: affiliations, as: string, repeatable: true }
    # a repeatable group -> the proc receives an Array of Hashes:
    - name: identifiers
      as: group
      repeatable: true
      fields:
        - { name: value, as: string }
        - { name: scheme, as: select, values: [ISNI, VIAF, ROR] }
```

How the pieces fit together:

- **Search picker.** The picker is the generic `linked_record` QA authority,
  mounted at `/authorities/search/linked_record/:source`. The source name is the
  sub-authority segment, so one authority serves every source — there is no
  per-source authority class. It delegates the query to the source's `search:`
  proc. A source registered without `search:` renders a plain text input.
- **Show-page link.** `Hyrax::CompoundLinkedRecordResolver` resolves the stored
  id to `[label, path]`. The link text is the record field named by
  `view: { label_field: }` when present, otherwise the source's `label:` proc.
  An id that no longer resolves renders as bare text, never a broken link.
- **Inline lookup-or-create.** When the sub-property declares `creatable: true`
  and the source registers a `create:` proc, a search that returns no matches
  offers an "Add new" form built from `create_fields`. Submitting it POSTs to
  `/linked_records/:source`, which calls the source's `create:` proc and selects
  the new record in the picker. Each `create_fields` entry declares its own
  input: `as: string` (text input) or `as: select` (a dropdown of `values:`),
  and `required:`.
- **Repeatable create-fields** (see `affiliations` and `identifiers` above). Mark
  any create-field `repeatable: true` and the "Add new" form renders add/remove
  rows for it. A repeatable **scalar** (`as: string`/`select`, no `fields:`)
  collects a plain **Array of strings** (`affiliations: ["A", "B"]`). A
  repeatable **group** (`as: group` with nested `fields:`) collects an **Array of
  Hashes**, one per non-blank row (`identifiers: [{ value: "…", scheme: "ISNI" }, …]`).
- **Indexing & reverse lookup.** A `linked_record` indexes as a single stored
  string `<compound>_<name>_ssim` (like an id), so you can reverse-look-up "which
  works reference this record?" with a Solr query on that field.

### Grouping (`group:` + `groups:`, optional)

Sub-properties can be clustered into labeled groups within each entry's card.
Membership is declared inline on each sub-property with `group: <key>`; the
parent compound declares the groups' display metadata in a `groups:` block keyed
by that key (label only — no field lists):

```yaml
participants:
  type: hash
  multiple: true
  groups:
    identity: { label: Identity }
    role:     { label: Role }

participant_name:
  type: string
  available_on: { properties: [participants] }
  group: identity
  form: { cols: 4 }
```

A sub-property with no `group:` falls in a single leading unlabeled group.
Groups appear in the order their first member is declared; sub-properties appear
in document order within their group. Per-field width is `form: { cols: }` (out
of 12), not a group-level setting.

### Indexing sub-properties (derived by default)

A sub-property is indexed to Solr by default — you do **not** declare its field
names. The indexer derives them as `<compound>_<name>_<suffix>` from the
compound name, the sub-property's in-compound `name:` (or key), and a suffix set
chosen by its `type:`:

| `type:`                  | Derived suffixes | Role |
|--------------------------|------------------|------|
| `string`                 | `_sim`, `_tesim` | facetable **and** full-text searchable |
| `controlled`             | `_sim`           | facetable only (a closed vocabulary needs no full-text) |
| `url`, `work_or_url`, `linked_record`, `id` | `_ssim` | stored exact-match string (reverse-lookup id) |
| `date_time`, `date`      | `_dtsi`          | date |

So `participants` with a `name`-aliased `title` (type `string`) is indexed to
`participants_title_sim` and `participants_title_tesim` with no `indexing:`
declaration. **Deriving per compound is what makes a reused sub-property safe:**
the same `title` definition folded into `participants` and `relationships`
produces `participants_title_*` and `relationships_title_*` — distinct fields,
no collision.

Two ways to depart from the default:

- **Override the field names** — declare an explicit `index_keys:`
  (non-flexible) / `indexing:` (flexible) list and it is used **verbatim**,
  replacing the derived set. Use this for a non-standard suffix choice (e.g. a
  free-text notes field you want searchable but not faceted: `indexing:
  [rights_notes_tesim]`, `_tesim` only) or a legacy field name.
- **Opt out of indexing** — set `indexing: false` / `index_keys: false`. The
  sub-property gets no Solr field of its own (it can still display; see below).

As with scalar fields, the non-field control tokens (`facetable`,
`stored_searchable`, `admin_only`, `editor_only`) are filtered out of an explicit
list if present.

Indexing a sub-property makes it **searchable/facetable** in Solr; it does **not**
make it appear as a column on the catalog/search-results page. The catalog
renders only the fields explicitly registered with Blacklight
(`config.add_index_field`) — compound sub-properties are not registered by default.
To show a sub-property in search results, register its derived Solr field name in
your `CatalogController` (e.g.
`config.add_index_field 'participants_name_tesim', label: 'Participant'`). The
show page and edit form render compounds regardless.

### `display:` (optional, default true)

A sub-property has two **independent** capabilities:

- **Display** — whether it appears on the work's show page. The indexer writes
  the compound's rows as a `<compound>_json_ss` blob the show page renders from;
  a sub-property is included in that blob unless it sets `display: false`.
- **Searchable indexing** — whether its value is written to its own Solr
  field(s). On by default (derived; see [Indexing](#indexing-sub-properties-derived-by-default)),
  turned off with `indexing: false` / `index_keys: false`.

Because these are separate, each sub-property can be in one of four states:

- **display + searchable** (the default) — `display` not false and indexing not
  opted out: shown on the work page **and** written to its (derived or explicit)
  Solr field.
- **display-only** — `indexing: false` (and `display` not false): stored in the
  rows and shown on the work page, but with no Solr field of its own, so it
  cannot be searched/faceted on independently.
- **searchable-only** — `display: false` (indexing not opted out): written to
  its Solr field but omitted from the show page.
- **neither** — `display: false` **and** `indexing: false`.

### `required:` (optional, default false)

Marks a sub-property as required within each populated row, or — when set on the
compound itself — marks the whole compound as required. See
[Required sub-properties](#required-sub-properties) below.

## Persisted shape

A compound persists as an array of plain string-keyed hashes — one key per
declared sub-property:

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
  writes each sub-property's value to its derived `<compound>_<name>_<suffix>`
  Solr fields (or an explicit `index_keys:`/`indexing:` override) and stores the
  displayable sub-properties as a `<compound>_json_ss` blob for the show page.

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
base work and collection indexers flatten them. Applications can add their own
compounds the same way and remove or override the samples in their own schema.

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

relationship_item:
  type: work_or_url
  available_on: { properties: [relationships] }
relationship_type:
  type: controlled
  available_on: { properties: [relationships] }
  authority: relationship_type
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
fields or unrenderable values. It enforces: each parent named in a subproperty's
`available_on: { properties: [...] }` is a declared `type: hash` compound
property; no two sub-properties of the same compound resolve to the same
in-compound name (a `name:` alias or the property key), which would otherwise
silently drop one when the loader folds members by that name (the same name
reused across *different* compounds is fine); a `type: controlled` sub-property
declares an option source (`authority:` or `values:`); and a compound parent
does **not** carry a top-level `indexing:` (indexing is declared per
sub-property — a top-level `indexing:` would point the catalog at a
`<compound>_tesim` field the indexer never writes).

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

relationship_item:
  type: work_or_url
  available_on: { properties: [relationships] }
  required: true
relationship_type:
  type: controlled
  available_on: { properties: [relationships] }
  authority: relationship_type
  required: true
relationship_note:
  type: string
  available_on: { properties: [relationships] }   # optional
```

Required sub-properties and required compounds render a `*` marker on the form
label. On save, `Hyrax::CompoundEntryValidator` (wired on the resource form)
adds one error per compound, keyed on the compound's attribute name, so the
failure is reported against that field. The rules are the same in both flex
modes.

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
(Bulkrax v9.5.0+). Each compound is an `object:` whose members map into a
`<compound>_attributes` numbered-key hash — the same shape the form's
`compound_attributes_populator` consumes (see [field_behaviors.md](field_behaviors.md#wiring-up-bulkrax-imports)
for the underlying mechanism, and the [Configuring Bulkrax wiki](https://github.com/samvera/bulkrax/wiki/Configuring-Bulkrax#mapping-into-form-_attributes-properties)
for the option reference).

### Field mapping

Declare one mapping per sub-property, all sharing the compound's `object:` value,
each with `nested_attributes: true`. The key written inside each row is the
sub-property's key (`name`, `role`, `title`, …). When that key is also a unique
top-level mapping key you can use it directly; otherwise give the entry a unique
mapping key and set the row key with `name:` (see "Shared and colliding row keys"
below).

```ruby
# In the host app's Bulkrax field-mapping configuration
'name'  => { from: ['participant_name'], object: 'participants', nested_attributes: true },
'role'  => { from: ['participant_role'], object: 'participants', nested_attributes: true },
'value' => { from: ['identifier_value'], object: 'identifiers',  nested_attributes: true },
```

### CSV columns

Columns are the mapping's `from:` name suffixed `_N`, one group per row in the
compound. For two participants on one work:

```
participant_name_1, participant_role_1, participant_name_2, participant_role_2
```

Each `_N` group becomes one entry in `participants_attributes` (index `N-1`),
folded by the populator into the persisted `Array<Hash>`.

### Shared and colliding row keys

A sub-property reused across compounds needs the same row key in each (e.g. a
`title` shared by `participants` and `relationships`), but Bulkrax mapping keys
must be globally unique. Bulkrax v9.5.1+ resolves this with `name:` (alias
`row_key:`), which sets the row key independently of the mapping key:

```ruby
'participant_title'  => { from: ['participant_title'],  object: 'participants',  nested_attributes: true, name: 'title' },
'relationship_title' => { from: ['relationship_title'], object: 'relationships', nested_attributes: true, name: 'title' },
```

The same applies when a sub-property's row key collides with an existing scalar
mapping (e.g. a compound `license` alongside a top-level `license`): give the
compound entry a unique mapping key and `name: 'license'`. See the
[Configuring Bulkrax wiki](https://github.com/samvera/bulkrax/wiki/Configuring-Bulkrax#reusing-a-row-key-across-objects)
for details.

Note: Bulkrax's controlled-URI sanitization does not currently descend into
compound sub-properties.
