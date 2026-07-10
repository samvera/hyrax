# Flexible Metadata

Hyrax v5.3 and later includes flexible metadata functionality that allows administrators to configure metadata schemas through the UI using M3 (Machine-readable Metadata Modeling) profiles. This feature is **disabled by default** and must be explicitly enabled.

### Key Features

- **UI-based Configuration**: Admins can define and manage metadata fields through the admin dashboard
- **Version Control**: Metadata profiles can be versioned, imported, and exported
- **Work Type Customization**: Control over field labels, required status, searchability, and more per Work Type
- **Reduced Developer Dependency**: Basic metadata changes no longer require developer involvement

> **Host applications.** A host application that layers on Hyrax may add its own fields, sort options,
> indexers, and profile-seeding behavior on top of what is described here. In particular, **Hyku** adds
> multi-tenant support (each tenant has its own profile), a per-tenant seeding task, a larger
> CatalogController, and additional indexers. If you are running Hyku, read this document for the
> fundamentals and then see Hyku's `documentation/flexible_metadata.md` for its differences.

> **See also.** The Samvera Confluence [Flexible Metadata](https://samvera.atlassian.net/wiki/spaces/hyraxdocs/pages/3382542341/Flexible+Metadata)
> page is a companion admin-facing guide with screenshots and a walkthrough; this document is the
> code-verified reference.

---

## Table of contents

- [How flexible metadata works](#how-flexible-metadata-works)
- [Configuration](#configuration)
- [Profile structure](#profile-structure)
- [Property keys reference](#property-keys-reference)
- [Controlled vocabularies & authorities](#controlled-vocabularies--authorities)
- [External-schema mappings (OAI-PMH, metatags, crosswalks)](#external-schema-mappings-oai-pmh-metatags-crosswalks)
- [What is required / what makes a profile invalid](#what-is-required--what-makes-a-profile-invalid)
- [Property order — how sequence drives forms & show pages](#property-order--how-sequence-drives-forms--show-pages)
- [What the profile cannot control — hardcoded couplings](#what-the-profile-cannot-control--hardcoded-couplings)
- [Renaming / aliasing a property (`name:`)](#renaming--aliasing-a-property-name)
- [Contexts](#contexts)
- [Property visibility flags](#property-visibility-flags)
- [Rich-text fields](#rich-text-fields)
- [HTML fields in catalog search results](#html-fields-in-catalog-search-results)
- [Featured display](#featured-display)
- [Related features](#related-features) — compound metadata, redirects, copy permalink
- [Schema versioning](#schema-versioning)
- [Admin UI](#admin-ui)
- [Developer notes](#developer-notes)

---

## How flexible metadata works

- Flexible metadata is **disabled by default**. It is enabled via environment configuration
  (`HYRAX_FLEXIBLE=true`) or by setting `Hyrax.config.flexible = true`.
- When enabled, the M3 profile controls deposit/edit **forms**, **Solr indexing**, and **work/collection
  show pages** for the classes configured as flexible.
- Every installation ships with a **default profile** at `config/metadata_profiles/m3_profile.yaml` that
  covers Hyrax core metadata and the base classes (`Hyrax::Work`, the admin-set model, the collection model,
  `Hyrax::FileSet`).
- Admins **download and upload** profiles through the admin dashboard. Each upload becomes a new active
  version; older works keep rendering under the version they were created with until edited.
- Supported classes: **Works, Collections, FileSets, and Admin Sets** — the shipped default profile drives
  properties for all four. Admin Sets additionally support [Contexts](#contexts), which scope fields to the
  Admin Set a work belongs to.

**Limitations.** Flexible metadata is a *configuration* layer over models that already exist. It **cannot
register new Work Types** — every class named in the profile must be a curation concern a developer has
already defined. It also cannot invent new Solr dynamic-field *suffixes* or make a field sortable/facetable on
its own: those depend on the Solr schema and the CatalogController (and, for `_ssi` sort fields, an indexer) —
see [What the profile cannot control](#what-the-profile-cannot-control--hardcoded-couplings). Within those
bounds it customizes **Works, Collections, FileSets, and Admin Sets**; a property may point `property_uri` at
any URI (including a new predicate) and index to any field using a supported suffix.

---

## Configuration

Setting the Hyrax configuration option `flexible` will allow the M3 profile loader and other flexible metadata elements to appear in the UI. It does not make any of the models themselves use flexible metadata.

There are **three independent layers** of configuration. Understanding how they compose is the key to setting
up flexible metadata correctly, especially when you want some classes flexible and others not, or you want the
profile (rather than fixed YAML files) to own certain fields.

| Layer | Question it answers | Set with |
|---|---|---|
| **1 — Feature** | Is flexibility *available* at all? | `HYRAX_FLEXIBLE=true` / `Hyrax.config.flexible` |
| **2 — Classes** | *Which models* use the m3 profile? | `HYRAX_FLEXIBLE_CLASSES` / `flexible_classes` / `acts_as_flexible` |
| **3 — Field source** | For a flexible model, does each field come from *fixed YAML* or the *profile*? | `HYRAX_DISABLE_INCLUDE_METADATA` / per-class `*_include_metadata` |

They stack: Layer 1 must be on for Layer 2 to do anything, and Layer 3 only matters for classes made flexible
in Layer 2. Expand each layer below for the details.

### Layer 1 — turn the feature on (global)

*Makes flexibility available; does not make any model flexible by itself.*

<details>
<summary>How Layer 1 works (the loader pair)</summary>

`HYRAX_FLEXIBLE=true` → `Hyrax.config.flexible?` enables the admin **Metadata Profiles** UI and makes
flexibility *available*. `Hyrax::Schema` exposes two loaders — `Hyrax::Schema.simple_schema_loader`
(`SimpleSchemaLoader`, fixed YAML) and `Hyrax::Schema.m3_schema_loader` (`M3SchemaLoader`, the DB-backed
profile). A schema include defaults to the simple loader; a flexible class gets the m3 loader because
`Hyrax::Resource.inherited` applies `acts_as_flexible_resource` (Layer 2), which passes the m3 loader
explicitly. Turning the feature on **does not, by itself, make any model flexible**.

</details>

### Layer 2 — choose which classes are flexible (per-class)

*Selects which models read the m3 profile; the rest keep their fixed schema. Mixed setups are supported.*

<details>
<summary>How Layer 2 works (<code>flexible_classes</code>, <code>acts_as_flexible</code>, mixed setups)</summary>

There are two ways to make models flexible:

- Setting the Hyrax configuration option `flexible_classes` (from the `HYRAX_FLEXIBLE_CLASSES` env var,
  comma-separated) toggles flexible metadata on for those classes automatically. When the env var is unset and
  `flexible?` is true, it defaults to the collection, file_set, and admin_set models.
- Manually adding `acts_as_flexible` to any model class that inherits from `Hyrax::Resource`.

These converge: `Hyrax::Resource.inherited` auto-applies flexibility to any subclass whose name appears in
`flexible_classes`. A non-flexible class simply answers `flexible? => false` and keeps its fixed schema.

> **Mixed setups are fully supported.** `flexible_classes` is a *list*. You can run one work type and the
> collection class on the m3 profile while another work type keeps its hardcoded YAML schema. Hyrax resolves
> each class independently (`admin_set_flexible?`, `collection_flexible?`, `file_set_flexible?`).

</details>

### Layer 3 — decide where each field's definition comes from (fixed YAML vs. the profile)

*For a flexible model, chooses whether basic/core metadata comes from fixed YAML includes or the m3 profile.
A model may mix both — as long as no single field is declared in both places.*

<details>
<summary>How Layer 3 works (include-metadata flags, mixing, the collision rule)</summary>

You may choose whether to include the basic metadata always or to make them part of the flexible metadata profile. If you wish to use the default provided M3 profile, you must set `admin_set_include_metadata`, `collection_include_metadata`, `file_set_include_metadata`, or `work_include_metadata` to `false` so that basic metadata can instead be read from the flexible metadata profile. You can also set all of these from the ENV by setting the `HYRAX_DISABLE_INCLUDE_METADATA` environment variable to `true`.

A flexible model must **not** `include` a fixed `core_metadata` / `basic_metadata` schema for a field the
profile *also* declares — the two definitions collide on that one attribute. Fields the profile does not
declare can safely remain in a fixed include (see the rule of thumb below). The sample app models use the flag
to gate their fixed includes:

```ruby
class GenericWorkResource < Hyrax::Work
  if Hyrax.config.work_include_metadata?          # false under HYRAX_DISABLE_INCLUDE_METADATA
    include Hyrax::Schema(:core_metadata)         # fixed YAML: config/metadata/core_metadata.yaml
    include Hyrax::Schema(:basic_metadata)        # fixed YAML: config/metadata/basic_metadata.yaml
    include Hyrax::Schema(:generic_work_resource) # fixed YAML: app-level schema
  end
  # When the class is flexible (name in flexible_classes), the m3 schema is merged on top of whatever
  # fixed schemas are still included — added, not swapped in.
end
```

> **Rule of thumb.** Define any given field in exactly **one** place: declaring the *same* field in both a
> fixed-YAML `include` and the m3 profile collides (two definitions for one attribute). But a single model may
> freely **mix** the two mechanisms across *different* fields — the m3 schema is *merged onto* the class's fixed
> schema, not a replacement (`acts_as_flexible_resource` adds the m3 `include`; at load time the singleton
> schema layers m3 attributes on top of the included YAML ones). This is a deliberate, supported pattern: keep
> fields you never want changed at runtime — the ones whose removal or rename would break the app — in a
> fixed-YAML `include`, and put the fields catalogers should be able to reconfigure in the m3 profile.
>
> Note the granularity of the flags: `HYRAX_DISABLE_INCLUDE_METADATA` and the per-class `*_include_metadata`
> flags toggle a model's fixed include as an all-or-nothing block (see the `if Hyrax.config.work_include_metadata?`
> gate above). To split fields — some fixed, some in the profile — on the *same* model, leave the flag on and
> gate the individual `include Hyrax::Schema(...)` calls yourself, making sure no field appears in both the
> included schema and the profile.

</details>

### Koppie Flexible
HYRAX_FLEXIBLE=true
HYRAX_FLEXIBLE_CLASSES=Hyrax::AdministrativeSet,CollectionResource,FileSet,GenericWork,Monograph
HYRAX_DISABLE_INCLUDE_METADATA=true

### Dassie Flexible
export HYRAX_FLEXIBLE=true
export HYRAX_FLEXIBLE_CLASSES=AdminSetResource,CollectionResource,Hyrax::FileSet,GenericWorkResource,Monograph
export HYRAX_DISABLE_INCLUDE_METADATA=true
export VALKYRIE_TRANSITION=true # this is needed to properly load Valkyrie models in Hyrax config and Bulkrax

---

## Profile structure

An M3 profile is a YAML document with these top-level sections:

| Key | Purpose | Required? |
|---|---|---|
| `m3_version` | M3 spec version. Must be exactly `1.0.beta2`. | ✅ Yes |
| `profile` | Administrative metadata about the profile itself | ✅ Yes |
| `classes` | The models / Work Types the profile defines fields for | ✅ Yes |
| `properties` | The metadata fields | ✅ Yes |
| `contexts` | Admin-Set-scoped field variations (see [Contexts](#contexts)) | Optional |
| `mappings` | Named mappings to external schemas (OAI-PMH, metatags, etc.) — see [External-schema mappings](#external-schema-mappings-oai-pmh-metatags-crosswalks) | Optional |

### `profile` section

`responsibility` (a URI, required) and `date_modified` (a quoted `YYYY-MM-DD`, required, tracking only).
Optional: `responsibility_statement` (shown as the profile title), `type` (shown as **Profile Type** in the
dashboard), `version` (a number, for user tracking — not the app's versioning).

```yaml
m3_version: 1.0.beta2
profile:
  date_modified: '2025-07-23'
  responsibility: https://samvera.org
  responsibility_statement: Hyrax Initial Profile
  type: Initial Profile
  version: 1
```

### `classes` section

Each entry declares a model or Work Type. **Every class requires a `display_label` string** (enforced by the
JSON schema). Class names are pattern-matched, and every class you list must be a **registered curation concern**
with the correct Valkyrie `...Resource` name — `ClassValidator` errors on an unregistered class or a
name/Valkyrie mismatch. The **AdminSet, Collection, and FileSet models must all be present** (`REQUIRED_CLASSES`;
a missing one is an error). Validation does **not** require any Work Type — a profile with none passes — but
without a Work Type class there is nothing to deposit works into. To remove an unused Work Type, omit it; adding
a *new* Work Type requires a developer (the profile cannot register a new curation concern).

```yaml
classes:
  AdminSetResource:
    display_label: Admin Set
  CollectionResource:
    display_label: PCDM Collection
  Hyrax::FileSet:
    display_label: File Set
  GenericWorkResource:
    display_label: Generic Work
```

The JSON schema also permits two optional per-class keys, but **Hyrax does not read either of them** — they are
descriptive metadata only, carried in the profile for documentation/interoperability:

- `schema_url` — a URI identifying the class in a local or shared ontology (e.g. `http://schema.org/Book`).
  Purely informational.
- `contexts` — a list of context names, described in the schema as "contexts in which this class may be used."
  This class-level key is **not** how context scoping works in Hyrax. Real context filtering is driven at the
  **property** level via `available_on.context` — see [Contexts](#contexts). Setting `contexts` on a *class*
  has no effect.

---

## Property keys reference

Each entry under `properties:` defines one metadata field. **A standalone property requires `display_label`,
`available_on`, and `range`.** (Compound subproperties are exempt — see [Related features](#related-features).)

Every other property key falls into one of six purpose groups below. Each group shows a one-line summary; open
the fold for the full key table.

### Identity & structure

*What the field is, where it lives, and its value type.* Includes the three required keys.

<details>
<summary>Keys: <code>available_on</code>, <code>display_label</code>, <code>property_uri</code>, <code>range</code>, <code>data_type</code>, <code>name</code></summary>

| Key | Purpose | Required? |
|---|---|---|
| `available_on` | Which classes and/or contexts the property applies to | ✅ Yes |
| `available_on.class` | List of class names (must be defined in `classes:`) | ✅ Yes (unless a compound subproperty) |
| `available_on.context` | List of context keys (should match a context in `contexts:`; not validated) | Optional |
| `display_label` | Human-readable label. A string, or a hash with `default` plus per-locale keys (`en`, `es`, …). May reference an i18n key. | ✅ Yes |
| `property_uri` | RDF predicate URI. | Required for core properties; recommended for all |
| `range` | XSD/RDF datatype URI (e.g. `http://www.w3.org/2001/XMLSchema#string`) | ✅ Yes |
| `data_type` | `array` (multi-valued) or `string` (single). Defaults to `string`. | Optional (must be `array` for `title` and `creator`) |
| `name` | Aliases the property to a different resource attribute (see [Renaming](#renaming--aliasing-a-property-name)) | Optional |

</details>

### Cardinality (required & multiplicity)

*How you make a property required and single- vs. multi-valued* — there is no separate "required" key; a
minimum of 1+ is what marks it required.

<details>
<summary>Key: <code>cardinality</code> (<code>minimum</code> / <code>maximum</code>)</summary>

| Declaration | Meaning |
|---|---|
| `cardinality: { minimum: 1 }` | Required, multi-valued |
| `cardinality: { maximum: 1 }` | Optional, single-valued |
| `cardinality: { minimum: 1, maximum: 1 }` | Required, single-valued |
| *(no cardinality)* | Optional, multi-valued |

`data_type: array` also forces multi-valued. `title` **must** have `cardinality.minimum >= 1`.

</details>

### Form

*How the field renders on the deposit/edit form.* At least one `form` value is needed for a field to appear on
the form.

<details>
<summary>Keys: <code>form</code> (<code>display</code>, <code>required</code>, <code>primary</code>, <code>multiple</code>, <code>input_type</code>, <code>cols</code>), <code>group</code></summary>

| Key | Effect |
|---|---|
| `form.display` | Whether the field renders. Implied by any other form value. |
| `form.required` | Field is required to submit (also implies `display`). |
| `form.primary` | `true` → renders "above the fold"; otherwise under **Additional fields**. |
| `form.multiple` | Allows multiple inputs (add-another control). |
| `form.input_type: rich_text` | WYSIWYG (TinyMCE) editor — see [Rich-text fields](#rich-text-fields). |
| `form.cols` | (Compound subproperties) input width on the 12-column grid. |
| `group` | (Compound subproperties) clusters the subproperty with its siblings; the parent's `groups:` supplies the label. |

Required fields are enforced on submit by `Hyrax::FlexibleFormBehavior#validate_flexible_required_fields`,
which adds a `:blank` error to any required field whose value is blank. Compound fields are skipped by that
check — their per-row sub-property requiredness is owned by `Hyrax::CompoundEntryValidator` — so a required
compound does not produce a duplicate "can't be blank" error.

</details>

### Indexing

*How the field goes into Solr* — literal field names (the suffix decides behavior) mixed with control-flag
tokens. In flexible mode the tokens also drive catalog columns/facets (see
[Catalog search results & facets](#catalog-search-results--facets--profile-driven-in-flexible-mode-but-not-their-order)).

<details>
<summary>Key: <code>indexing</code> (Solr field names + <code>facetable</code> / <code>stored_searchable</code> / <code>admin_only</code> / <code>editor_only</code>)</summary>

The `indexing:` list mixes **literal Solr field names** (the suffix decides behavior — `_tesim` full-text,
`_sim`/`_ssim` facet/exact string, `_dtsi` date) with **control-flag tokens**:

| Token | Effect |
|---|---|
| `facetable` | produces the `_sim` facet field **and** (flexible mode) auto-registers the catalog sidebar facet via `FlexibleCatalogBehavior`; omitting it removes the facet |
| `stored_searchable` | field is stored and full-text searchable; (flexible mode) also auto-registers the catalog search-results column and adds the field to relevance search |
| `admin_only` | property hidden from the catalog entirely; show-page only for admins |
| `editor_only` | property hidden from the catalog entirely; show-page only for users who can edit the record |

The four control tokens are read but not treated as Solr fields (`AttributeDefinition#index_keys` filters them
out). See [Property visibility flags](#property-visibility-flags) for `admin_only`/`editor_only`.

```yaml
indexing:
  - subject_sim
  - subject_tesim
  - facetable
```

</details>

### View (show page & catalog)

*How the field renders and links on the show page and in catalog results.* The `view:` block controls
rendering; `render_as` selects a renderer and, on both surfaces, what each value links to.

<details>
<summary>Key: <code>view</code> (<code>html_dl</code>, <code>render_as</code>, <code>search_field</code>, <code>position</code>, <code>show_page</code>, <code>search_results</code>, …) + <code>render_as</code> values</summary>

| Key | Effect |
|---|---|
| `view.html_dl: true` | Renders in the definition-list (`<dt>/<dd>`) layout used by show pages. |
| `view.render_as` | Selects a renderer (full list below). |
| `view.search_field` | Overrides the Solr field a linked value points at (pair with `render_as: linked` or `faceted`; defaults to the property name, i.e. `<property>_sim` for `faceted`). |
| `view.render_term` | Renders from a different presenter method / Solr term than the attribute name. |
| `view.position: featured` | Promotes the field above the metadata table (see [Featured display](#featured-display)). |
| `view.search_results_truncate` | Catalog snippet length for `render_as: html` fields (see [HTML fields in catalog search results](#html-fields-in-catalog-search-results)). |
| `view.show_page: false` | Hides the field from the show page for everyone (still stored/indexed). |
| `view.search_results: false` | Drops the field's catalog search-results column (still on the show page; still facetable). |
| `view.display: card` | (Compound) render the compound as its own titled card. |

**`view.render_as` values** (`render_as: <name>` → `Hyrax::Renderers::<Name>AttributeRenderer`):

| `render_as` | Renders as |
|---|---|
| *(none)* | plain attribute value (default) |
| `faceted` | value linked to its **facet** search at `<field>_sim` (override the field with `search_field:`) |
| `linked` | value linked into a **keyword** search (pair with `search_field:`) |
| `external_link` | value auto-linked to the **external URL it contains** |
| `date` | formatted date (no link) |
| `license` / `rights_statement` | value linked to its **authority URI**, shown with the authority's human label |
| `html` | stored HTML, sanitized against a fixed allow-list ([rich text](#rich-text-fields)) |
| `compound` | hierarchical compound rendered as a definition list / card |
| `redirects_label` | each redirect path linked to itself (text = full URL) |

</details>

#### Linking a field's values — exactly what each link points at

Field values can become links on **two independent surfaces** — the work/collection **show page** and the
**catalog** search-results page. Both are driven from the m3 profile, but they run through *different code*
(the show page uses attribute **renderers**; the catalog uses Blacklight **helper methods** that
`Hyrax::FlexibleCatalogBehavior` auto-wires from the same `render_as`). The link a value points at falls into
three kinds:

- **Facet filter** — `/catalog?f[<field>_sim][]=<value>`: narrows results to documents whose facet equals that
  exact value.
- **Keyword search** — `/catalog?search_field=<field>&q=<value>`: runs a query for that value.
- **Outward link** — the link points at the **value's own URI/path** (an authority URI, an external URL, a
  redirect path), *not* into search.

Getting the wrong one is the usual cause of "the link goes somewhere I didn't expect." The tables below say
precisely where each link lands.

<details>
<summary><strong>Per-surface link tables + worked example</strong> (show-page renderers, catalog helpers)</summary>

##### Show-page links (attribute renderers, selected by `view: { render_as: ... }`)

| `render_as` | Link kind | Points at |
|---|---|---|
| `faceted` | Facet filter | `/catalog?f[<field>_sim][]=<value>`. `<field>` = `search_field` or the property name; the renderer **appends `_sim`**, so the property must index a `_sim` field. |
| `linked` | Keyword search | `/catalog?search_field=<field>&q=<value>` (value **not** quoted). `<field>` = `search_field` or the property name (no suffix appended). |
| `external_link` | Outward | The **URL contained in the value** (auto-linked, external-link icon). Nothing to configure beyond `render_as`. |
| `rights_statement` | Outward | The **rights-statement authority URI in the value**, opened in a new tab; link text is the authority's human label. Rendered as plain text if the value is not an http/https URI. |
| `license` | Outward | The **license authority URI in the value**, new tab, label from the license authority. Plain text if not a URI. |
| `redirects_label` | Outward | The **redirect path itself** (a relative href resolved against the current host); link text is the full absolute URL. |

So on the show page: `faceted` → facet filter, `linked` → keyword query, and
`external_link` / `rights_statement` / `license` / `redirects_label` link out to the value's own target.
`search_field:` only affects `faceted` and `linked`.

##### Catalog-column links (Blacklight helpers, auto-wired in flexible mode by `FlexibleCatalogBehavior`)

| Trigger | Link kind | Points at |
|---|---|---|
| property has `facetable` in `indexing:` | Facet filter | `/catalog?f[<property>_sim][]=<value>` — same target as show-page `faceted`. Set via Blacklight's `link_to_facet` on the column **whenever the property is facetable, regardless of `render_as`**. |
| `render_as: linked` | Keyword search | `/catalog?search_field=<field>&q="<value>"` — note the catalog helper **quotes** the value (exact-phrase), unlike the show-page `linked` renderer. |
| `render_as: external_link` | Outward | The **URL in the value** (auto-linked, external-link icon). |
| `render_as: rights_statement` | Outward | The **rights authority URI**, with its label. |
| `render_as: html` | *(no link)* | Strips tags and renders a truncated plain-text snippet — wired only so raw HTML isn't dumped into the column. |

Two couplings that trip people up:

- **`faceted` (show page) and the catalog facet link are triggered differently.** The show-page facet link
  needs `render_as: faceted`; the catalog column's facet link appears automatically whenever the property is
  `facetable` — no `render_as` required. Both land on `<property>_sim`.
- **The catalog `linked` helper quotes the query** (`q="value"`), the show-page `linked` renderer does not
  (`q=value`). Same destination, slightly different query.

##### Worked example — a subject that links to its facet on both surfaces

```yaml
subject:
  available_on: { class: [GenericWorkResource] }
  display_label: { default: Subject }
  property_uri: http://purl.org/dc/terms/subject
  range: http://www.w3.org/2001/XMLSchema#string
  indexing:
    - subject_sim              # the _sim facet field the facet links target
    - subject_tesim
    - facetable                # catalog: auto-registers the sidebar facet + column facet link
    - stored_searchable        # catalog: auto-registers the results column + relevance search
  view:
    html_dl: true
    render_as: faceted         # show page: each value links to the subject facet (subject_sim)
    # search_field: subject    # optional; defaults to the property name
```

Result: on the **show page** each subject value links to `f[subject_sim][]=<value>` (because `render_as:
faceted`); in the **catalog** the subject column value links to the same facet (because the property is
`facetable`), the subject facet appears in the sidebar, and the results column is present.

For a **keyword** link instead of a facet link, use `render_as: linked` (and pair with `search_field:` if the
searched field differs from the property name). For an **outward** link to the value's own URI, use
`external_link`, `rights_statement`, `license`, or `redirects_label` — none of these touch `search_field`.

> **Note.** Facet/column *presence* is profile-driven in flexible mode, but facet/column **order** and **sort
> options** still come from the CatalogController — see
> [Catalog search results & facets](#catalog-search-results--facets--profile-driven-in-flexible-mode-but-not-their-order).

</details>

### Documentation-only keys (not rendered)

*Descriptive metadata Hyrax stores but never renders or consumes.*

<details>
<summary>Keys: <code>definition</code>, <code>usage_guidelines</code>, <code>sample_values</code>, <code>index_documentation</code>, <code>requirement</code>, <code>controlled_values</code></summary>

`definition` (help text with `default` + per-locale keys), `usage_guidelines`, `sample_values`,
`index_documentation`, `requirement`, `controlled_values` (`format` + `sources`).

> **`controlled_values` on a standalone property is documentation-only** — the loader does not read it to
> build a dropdown or autocomplete. To actually attach a controlled vocabulary to a field, see
> [Controlled vocabularies & authorities](#controlled-vocabularies--authorities).

</details>

### Example property (all groups together)

```yaml
title:
  available_on:
    class:
      - AdminSetResource
      - Hyrax::FileSet
      - CollectionResource
      - GenericWorkResource
  cardinality:
    minimum: 1
  data_type: array
  display_label:
    default: Title
    en: "Title"
    es: "Título"
  indexing:
    - title_sim
    - title_tesim
  form:
    required: true
    primary: true
  property_uri: http://purl.org/dc/terms/title
  range: http://www.w3.org/2001/XMLSchema#string
  view:
    html_dl: true
```

---

## Controlled vocabularies & authorities

This is the single reference for making a field controlled (a dropdown, an autocomplete against a local list,
or a typeahead against a remote authority). The most important thing to understand first:

> **The profile's `controlled_values` key does NOT wire an authority.** On a standalone property it is
> documentation-only — the schema loader never reads it to choose a form input (the loader only ever supplies a
> hardcoded `controlled_values` default; it does not consume yours). The shipped profile sets
> `controlled_values: { format: …#string, sources: ["null"] }` on many fields precisely because `"null"` means
> "free text / no authority." Whether a **standalone** field is controlled is decided by its **field name**, not
> by `controlled_values`. Compound sub-properties are the exception — they use a real `authority:` key (see D).

The mechanisms below cover standalone properties (A–C shipped by field name, D your own) and compound members
(E). Pick the row that matches what you're doing.

<details>
<summary><strong>The five mechanisms (A–E) + how "controlled" is detected</strong></summary>

### A. Built-in controlled fields (rendered as a `<select>` from an authority service)

Three field **names** are wired to Hyrax authority *services* and always render as dropdowns, regardless of
what the profile says:

| Property name | Options come from | Renderer service |
|---|---|---|
| `license` | `Hyrax.config.license_service_class` (`config/authorities/licenses.yml`) | `records/edit_fields/_license` |
| `rights_statement` | `Hyrax.config.rights_statement_service_class` (`config/authorities/rights_statements.yml`) | `records/edit_fields/_rights_statement` |
| `resource_type` | `Hyrax::ResourceTypesService` (`config/authorities/resource_types.yml`) | `records/edit_fields/_resource_type` |

To opt in, **name the property `license` / `rights_statement` / `resource_type`** in the profile. The stored
value is the authority URI (or term); the dropdown preserves an existing value even if it's no longer offered
(`include_current_value`). On the show page these render via `render_as: license` / `rights_statement`, linking
the URI to its human label (see [Linking a field's values](#linking-a-fields-values--exactly-what-each-link-points-at)).

These three ship as `config/authorities/*.yml` in the sample apps and can be edited there (a developer/app task,
not a profile task).

### B. Field-name autocomplete against a local authority

A few more field **names** ship with dedicated edit-field partials that render an autocomplete pointed at a
**local QA authority** endpoint:

| Property name | Autocomplete endpoint | Input style |
|---|---|---|
| `subject` | `/authorities/search/local/subjects` | multi-value text with typeahead |
| `language` | `/authorities/search/local/languages` | multi-value text with typeahead |

To opt in, name the property `subject` or `language`. **Caveat:** the sample apps do **not** ship
`config/authorities/subjects.yml` or `languages.yml`, so these autocompletes return nothing until the app adds
those local authority files. The QA engine is mounted at `/authorities` (`mount Qa::Engine => '/authorities'`).

### C. Field-name typeahead against a remote authority

`based_near` (location) ships a partial that renders a `controlled_vocabulary` input with a typeahead against a
**remote** authority — Geonames — at `/authorities/search/geonames`
(`records/edit_fields/_based_near`). The stored value is a Geonames URI; on the show page the catalog uses the
indexer-produced `based_near_label_*` field for the human label (see the location example in
[Fields pre-declared in the CatalogController](#fields-pre-declared-in-the-catalogcontroller-must-match-exact-solr-field-names)).

> **How A/B/C are actually chosen.** The edit form resolves each field to a partial named
> `records/edit_fields/<field_name>` (hydra-editor convention, via `render_edit_field_partial`). If a partial
> with that name exists, it wins; otherwise the field falls back to a plain text/multi-value input. So a
> standalone field becomes controlled **only** when its name matches one of the shipped partials above (or one
> your app adds). Renaming `subject` to `topic` in the profile silently drops the autocomplete — the `_subject`
> partial no longer matches.

### D. Adding your own standalone controlled field (developer task)

Because A–C key on field name, giving a *new* standalone property a controlled input is a **developer task**,
not a profile task: add a `records/edit_fields/_<field_name>.html.erb` partial (following `_subject` for a local
authority or `_based_near` for a remote one), and, for a local authority, a `config/authorities/<name>.yml`
file. The profile alone cannot point an arbitrary standalone property at an authority.

### E. Controlled compound sub-properties (this one uses a real `authority:` key)

Inside a compound (`type: hash`), a member declared `type: controlled` **is** driven by the profile — it uses
an `authority:` key (or an inline `values:` list), unlike standalone properties:

```yaml
# inline list — no authority file needed
identifier_type:
  type: controlled
  values:
    - { label: DOI, value: doi }
    - { label: ISBN, value: isbn }

# or an existing QA local authority (config/authorities/<name>.yml)
role:
  type: controlled
  authority: contributor_role
```

Compound members also support `work_or_url` (internal work picker or external URL) and `linked_record` (a
reference to a row in a host-registered database table, with an inline search-or-create picker). These are the
**internal-vocabulary** mechanisms. Full details — supported member types, the `authority:` / `values:` options,
registering a `linked_record` source, and show-page rendering — are in
[`documentation/compound_fields.md`](compound_fields.md).

### How "controlled" is detected (for the rich-text warning)

Because there is no single declarative "controlled" flag, `Hyrax::FlexibleSchemaValidators::RichTextValidator`
treats a property as controlled when **any** of these holds, and warns if you also put `form: { input_type:
rich_text }` on it:

- `controlled_values.sources` names a real authority (anything other than the `"null"` sentinel), or
- the property name is one of `rights_statement`, `license`, `resource_type`, `based_near`, `language`,
  `access_right` (its `CONTROLLED_BY_CONVENTION` list), or
- it is a compound sub-property declared `type: controlled`.

This detection list is a conservative approximation, not the exact set of fields that render as dropdowns: e.g.
`subject` renders a controlled autocomplete but isn't in the list, and `access_right` is in the list but its
shipped partial is a plain textarea. Use the tables in A–C above for what actually renders.

</details>

---

## External-schema mappings (OAI-PMH, metatags, crosswalks)

The profile can record, per property, how that field maps to an external target schema — Simple Dublin Core,
Qualified Dublin Core, MODS, HTML metatags, and so on. This is the data an **OAI-PMH provider** (or any
crosswalk/export) uses to know that, say, `title` becomes `dc:title` in a Simple DC record.

> **Scope — read this first.** Hyrax stores and exposes the mapping *data*; it does **not** ship an OAI-PMH
> provider that serves a feed. There is no OAI route, no OAI catalog configuration, and no OAI gem in Hyrax or
> its sample apps (dassie/koppie). The profile is the *source of the crosswalk*; the code that turns it into an
> actual OAI feed lives in the **downstream application** (e.g. Hyku). If you are building an OAI feed on top of
> Hyrax, this section tells you where the mapping lives and how to read it; see your application's docs for the
> provider itself.

<details>
<summary><strong>Declaring mappings, reading them (<code>mappings_data_for</code>), and limits</strong></summary>

### Declaring mappings

Two parts work together.

**1. Register the target schemas** in the top-level `mappings:` section — each key is a mapping *name*, with a
human `name:` label. The names are conventions chosen by the profile, not a fixed list; the shipped profile
uses these:

```yaml
mappings:
  blacklight:
    name: Additional Blacklight Solr Mappings
  metatags:
    name: Metatags
  mods_oai_pmh:
    name: MODS OAI PMH
  qualified_dc_pmh:
    name: Qualified DC OAI PMH
  simple_dc_pmh:
    name: Simple DC OAI PMH
```

**2. Map each property** by adding a `mappings:` block to the property, keyed by those same mapping names. The
value is the target element/expression in that schema:

```yaml
title:
  # …
  indexing:
    - title_sim
    - title_tesim
  mappings:
    metatags: twitter:title, og:title
    mods_oai_pmh: mods:titleInfo/mods:title
    qualified_dc_pmh: dcterms:title
    simple_dc_pmh: dc:title
  property_uri: http://purl.org/dc/terms/title
```

A property with no `mappings:` block is simply absent from every crosswalk. In the **shipped default profile,
only `title` declares mappings** — every other property would need a `mappings:` block added before it appears
in an OAI/crosswalk record.

### Reading the mapping data

`Hyrax::FlexibleSchema.mappings_data_for(mapping_name)` (default `'simple_dc_pmh'`) returns, for the current
active profile, every property that declares that mapping, paired with its Solr index keys and the target:

```ruby
Hyrax::FlexibleSchema.mappings_data_for('simple_dc_pmh')
# => { "title" => { "indexing" => ["title_sim", "title_tesim"],
#                   "mappings" => { "simple_dc_pmh" => "dc:title" } } }
```

The `indexing` keys tell a provider **which Solr field to read the value from**; the `mappings` value tells it
**which target element to emit**. An unknown mapping name, or no active profile, returns `{}`. This method is
the intended integration point — a downstream OAI provider calls it to build each record. Hyrax itself has no
caller.

### Notes and limits

- **Mapping names are free-form** (snake_case). `simple_dc_pmh` / `qualified_dc_pmh` / `mods_oai_pmh` /
  `metatags` are just the shipped conventions; a profile may define others (the JSON schema's examples include
  `dc`, `dpla`, `datacite`). A downstream provider must agree on the names it looks up.
- **The mapping value is an opaque string** to Hyrax — `dc:title`, `mods:titleInfo/mods:title`,
  `twitter:title, og:title`. Hyrax does not parse or validate it against the target schema; interpreting it is
  the provider's job.
- **No validator checks mappings.** A typo in a mapping name or target simply yields nothing for that field in
  the crosswalk; there is no upload-time error or warning.
- **`metatags` is the same mechanism, not OAI.** The `metatags` mapping feeds HTML `<meta>` tags (Twitter/OG)
  rather than an OAI record, but it is declared and read the same way.

</details>

---

## What is required / what makes a profile invalid

On upload, `Hyrax::FlexibleSchema` runs `FlexibleSchemaValidatorService#validate!`, which runs **nine
validators**. **Errors block the save; warnings save the profile but flash a notice.** This table is the
authoritative answer to "what is required."

| Validator | Rule enforced | Result |
|---|---|---|
| **SchemaValidator** (JSON schema) | Structural correctness: required keys present, `available_on` non-empty, `display_label`/`range` on standalone properties, key-name patterns. | Error |
| **required classes** | The AdminSet, Collection, and FileSet models are all present in `classes:`. | Error |
| **ClassValidator** (availability) | Every class is a registered curation concern; Valkyrie `...Resource` naming is correct. | Error |
| **ClassValidator** (references) | Every class named in a property's `available_on.class` is defined in top-level `classes:`. | Error |
| **ExistingRecordsValidator** | A class that has existing records in the repository cannot be dropped from the profile. | Error |
| **CoreMetadataValidator** | Core properties (`title`, `date_modified`, `date_uploaded`, `depositor`, `creator`) exist, have the right `data_type`, the required `index_keys`, the right `property_uri`, and are available on all classes; `title` cardinality ≥ 1. (`keyword` is *not* required, but if present must be `data_type: array`.) | Error |
| **label property** | A `label` property exists and is available on the FileSet model. | Error |
| **CompoundValidator** | Each subproperty's parent is a `type: hash`; `controlled`/`linked_record` members declare an option source; no two members resolve to the same in-compound name; a compound parent has no top-level `indexing:`. | Error |
| **RedirectsValidator** | When the redirects config **and** Flipflop are both on, a `redirects` (`type: hash`) property must exist on a work/collection class. A stale `redirects` property when gated off warns. | Error / Warning |
| **SortPropertiesValidator** | Catalog sort fields should be available on all work types. | Warning |
| **RichTextValidator** | `form: { input_type: rich_text }` on a controlled-vocabulary property. | Warning |
| **SearchResultsTruncateValidator** | `view: { search_results_truncate: N }` without `render_as: html` (silent no-op). | Warning |

> **Gotcha — `depositor` indexing.** `core_metadata.yaml` requires **both** `depositor_ssim` **and**
> `depositor_tesim`, and the shipped default `m3_profile.yaml` lists only `depositor_tesim` — so the shipped
> profile does **not** pass `CoreMetadataValidator`. This matters differently on each load path:
>
> - **Upload** (`Admin::MetadataProfilesController#import`) runs validation — a profile missing `depositor_ssim`
>   is rejected with an error.
> - **Lazy default** (`FlexibleSchema.create_default_schema`, triggered by the m3 loader when no row exists)
>   uses `save(validate: false)`, so the shipped profile persists despite the missing key.
> - **Seed task** (`RequiredDataSeeder` → `FlexibleProfileSeeder.generate_seeds`) uses `first_or_create`, which
>   **runs validations**. On the invalid shipped profile the validation fails and — because `first_or_create`
>   does not raise — the row is silently **not** persisted. A later read then falls back to the lazy
>   `create_default_schema` path. Net effect: the default still loads, but not via the seed task.
>
> If you hand-edit and re-upload a profile, include both `depositor` index keys so it survives the upload
> validation.

### Minimal valid profile

The smallest profile that can successfully create works. Every key shown is required; comments mark which
values you may change.

```yaml
---
m3_version: 1.0.beta2                 # Do not modify
profile:
  date_modified: '2025-07-22'         # Free to change (tracking only)
  responsibility: https://test.com    # Free to change (must be a URI)
classes:
  AdminSetResource:                   # Required class
    display_label: Admin Set          # Label is free to change
  CollectionResource:                 # Required class
    display_label: PCDM Collection
  Hyrax::FileSet:                     # Required class
    display_label: File Set
  GenericWorkResource:                # At least one Work Type required
    display_label: Generic Work
properties:
  title:
    available_on:
      class: [AdminSetResource, Hyrax::FileSet, CollectionResource, GenericWorkResource]
    cardinality: { minimum: 1 }       # Makes title required — do not modify
    data_type: array                  # Required for title
    display_label: { default: Title }
    indexing: [title_sim, title_tesim]
    form:
      required: true                  # Without this there is no title input on the form
      primary: true                   # Without this the input hides under "Additional fields"
    property_uri: http://purl.org/dc/terms/title
    range: http://www.w3.org/2001/XMLSchema#string
  date_modified:
    available_on:
      class: [AdminSetResource, Hyrax::FileSet, CollectionResource, GenericWorkResource]
    display_label: { default: Date Modified }
    range: http://www.w3.org/2001/XMLSchema#dateTime
    property_uri: http://purl.org/dc/terms/modified
  date_uploaded:
    available_on:
      class: [AdminSetResource, Hyrax::FileSet, CollectionResource, GenericWorkResource]
    display_label: { default: Date Uploaded }
    range: http://www.w3.org/2001/XMLSchema#dateTime
    property_uri: http://purl.org/dc/terms/dateSubmitted
  depositor:
    available_on:
      class: [AdminSetResource, Hyrax::FileSet, CollectionResource, GenericWorkResource]
    display_label: { default: Depositor }
    indexing: [depositor_ssim, depositor_tesim]   # BOTH keys required (see gotcha above)
    range: http://www.w3.org/2001/XMLSchema#string
    property_uri: http://id.loc.gov/vocabulary/relators/dpt
  creator:
    available_on:
      class: [AdminSetResource, Hyrax::FileSet, CollectionResource, GenericWorkResource]
    data_type: array
    display_label: { default: Creator }
    indexing: [creator_sim, creator_tesim]
    range: http://www.w3.org/2001/XMLSchema#string
    property_uri: http://purl.org/dc/elements/1.1/creator
  label:
    available_on:
      class: [Hyrax::FileSet]         # FileSet is the only class the label property needs
    display_label: { default: Label }
    range: http://www.w3.org/2001/XMLSchema#string
```

---

## Property order — how sequence drives forms & show pages

The **order you list properties in the profile is significant** for forms and show pages. The schema loader
iterates the profile's `properties:` hash in document (YAML) order and preserves that order there. The
**catalog is a hybrid**: in flexible mode `FlexibleCatalogBehavior` walks the profile in property order and, for
each property, *either* updates a column/facet the CatalogController already declared (which keeps its
controller position) *or* appends a new one (in profile order). So a field the controller pre-declares is fixed
where the controller put it, but every other profile field's column/facet lands in **profile order**, after the
pre-declared ones. Reordering the profile *does* move those. See
[Catalog search results & facets](#catalog-search-results--facets--profile-driven-in-flexible-mode-but-not-their-order)
below for the precise rule.

### Profile-driven order (deposit form, edit form, work show page)

These follow the profile's property order directly. **Reorder the properties in the YAML and these reorder.**

| Surface | How order is derived |
|---|---|
| **Deposit / edit form — "primary" fields** (above the fold) | `primary_terms`: the profile-ordered fields whose `form: { primary: true }`, in profile order. |
| **Deposit / edit form — "Additional fields"** (below the fold) | `secondary_terms`: the remaining displayed fields, in profile order. |
| **Work show page** (the metadata table) | `view_options_for` → `view_definitions_for` iterates the same profile hash; `_attribute_rows.html.erb` renders each in profile order. |

A field's **section** on the form is set by `form: { primary: }`, but its **position within that section** is
its position in the profile. To move a field up on the form or show page, move its property block up in the
YAML. (Two fixed exceptions: on a flexible form the hidden `schema_version` and `contexts` fields are prepended
to the primary terms; compounds are pulled out of the scalar term lists and rendered by their own partials.)

### Catalog search results & facets — profile-driven in flexible mode (but not their *order*)

In flexible mode the catalog **does** read the profile. `Hyrax::FlexibleCatalogBehavior` — included in the
CatalogController when `Hyrax.config.flexible?` — runs `load_flexible_schema` at controller load and, from the
active profile, automatically:

- **Registers a search-results column** (`add_index_field` on `<property>_tesim`) for every property that is
  stored-searchable (declares `stored_searchable` *or* a `<property>_tesim` key in `indexing:`), unless
  `view: { search_results: false }` is set. If the property is *already* declared in the CatalogController, it
  updates that field (label, `itemprop`, `link_to_facet`, helper method) instead of adding a duplicate.
- **Registers a facet** (`add_facet_field` on `<property>_sim`) for every property whose `indexing:` includes
  `facetable`, and **removes** the facet for any property that does *not* declare `facetable`.
- **Sets `link_to_facet`** on a column when the property is facetable, so the column value links to its facet.
- **Wires the index-view helper method** for `render_as: linked` / `external_link` / `rights_statement` / `html`
  so those columns render as links/HTML rather than raw text.
- **Adds the field to the `qf` relevance list** (`all_fields` search) so it is full-text searchable.

So adding a `facetable`, `stored_searchable` property to the profile makes its facet and column appear in the
catalog **without editing the CatalogController**.

**Ordering is a hybrid, not purely controller-driven.** `load_flexible_schema` iterates the profile in property
order and calls `add_index_field` / `add_facet_field` as it goes. Because Blacklight's config is
insertion-ordered, this means:

- A column/facet the CatalogController **pre-declares** keeps its position — the behavior *updates it in place*
  (label, `link_to_facet`, helper) rather than re-adding it.
- Every **other** profile property's column/facet is **appended in profile order**, after the pre-declared
  ones. Reordering those properties in the profile **does** reorder them in the catalog.

So the effective order is: controller-declared fields first (in controller order), then the remaining
profile fields (in profile order). In the shipped setup the CatalogController template pre-declares a limited
set, so most fields fall into the second, profile-ordered group.

What the profile does **not** control at all is **sort options** (see
[below](#the-big-one-sort-fields-use-different-solr-fields-than-the-profile-declares) — sort still requires
`add_sort_field` and, for `_ssi` fields, an indexer).

<details>
<summary><strong>Sharp edges worth knowing</strong> (facet token, per-request deletion, empty shipped profile)</summary>

- **Facets key on the literal `facetable` token in `indexing:`** — not on a `_sim` field being present, not on
  `data_type`, and **not** on `view: { render_as: faceted }`. (`render_as: faceted` is the show/index-page
  link-to-facet renderer; it does not register a sidebar facet.)
- **`load_flexible_schema` runs on every request** (from the controller's `initialize`), *after* the class-body
  `add_facet_field` calls. So for a property `foo` present in the profile **without** `facetable`, it
  **deletes** the `foo_sim` facet — even if the CatalogController declared `add_facet_field "foo_sim"`. The
  deletion only targets `<property>_sim` where `<property>` is a profile key, so a hand-declared facet on a
  *different* field name is untouched (e.g. `based_near_label_sim` survives because the profile property is
  `based_near`, not `based_near_label`).
- **The shipped default `m3_profile.yaml` contains no `facetable` tokens at all.** As a result none of its
  properties register a sidebar facet, and any matching `<property>_sim` facet declared in the controller is
  stripped. To get a sidebar facet, add `facetable` to that property's `indexing:` — this is the intended
  workflow: facets are managed in the profile, not the controller.

</details>

> **Rule of thumb.** In flexible mode, catalog columns and facets *appear* from the profile automatically, and
> profile order **does** order them — except for fields the CatalogController pre-declares (those keep their
> controller position) and **sort options** (always controller + indexer). Form and show-page order are fully
> profile-driven. If a profile reorder "didn't move" a catalog field, that field is almost certainly one the
> CatalogController declares explicitly.

---

## What the profile cannot control — hardcoded couplings

Some behavior is fixed in code and **cannot** be changed by the m3 profile — and, more subtly, some fields
that *look* optional are actually **required by hardcoded config elsewhere** (chiefly the CatalogController).
A profile can pass every validator and still leave a feature silently broken because it didn't produce the
exact Solr field name (with the exact suffix) that a fixed config expects.

Because each application's `CatalogController` differs, treat the specifics below as **"watch for these
situations"** guidance. The exact field list in your app is whatever your `app/controllers/catalog_controller.rb`
declares — the point is the *class* of coupling, and where to look. (A host application such as Hyku ships a
much larger CatalogController than the base Hyrax template; see that application's own documentation.)

### The big one: sort fields use different Solr fields than the profile declares

This is the most common "required but not obvious" trap. A profile typically indexes `title` as `title_sim`
+ `title_tesim`. But a **"Sort by Title"** option does **not** sort on either of those — a title sort needs a
single-valued string field (a `_ssi`), produced by an **indexer**, not by the profile's `indexing:` keys. The
sort label and the Solr field it targets are hardcoded in the CatalogController's `add_sort_field` calls.

The base Hyrax `catalog_controller.rb` generator template ships only these sort options, all on
**system-generated** date fields:

| Sort label | Solr field | Source |
|---|---|---|
| relevance | `score`, then `system_create_dtsi` | system-generated |
| date uploaded ▲/▼ | `system_create_dtsi` | system-generated (Fedora create time) |
| date modified ▲/▼ | `system_modified_dtsi` | system-generated (Fedora modified time) |

Base Hyrax has **no** title, author, or `date_created` sort out of the box — those `_ssi` sort fields, if you
want them, must be written by an indexer and wired up with `add_sort_field`.

**Why this matters for a profile author:** the `_ssi`/`_dtsi` sort fields are **not** something you add via
the profile's `indexing:` list. `system_create_dtsi` / `system_modified_dtsi` are system-generated, and any
`_ssi` string-sort field (e.g. `title_ssi`) must be written by an indexer. So **you cannot make an arbitrary
property sortable purely through the profile** — sorting on a new field requires an indexer change and an
`add_sort_field` entry, both developer tasks. The `SortPropertiesValidator` only *warns* about coverage of the
sort properties it can see (excluding the `score` / `system_create` / `system_modified` system fields); a green
profile does not guarantee a working sort.

### Fields *pre-declared* in the CatalogController must match exact Solr field names

`Hyrax::FlexibleCatalogBehavior` **adds** profile properties that are not already in the CatalogController
(`add_index_field` on `<property>_tesim`, `add_facet_field` on `<property>_sim`). But when a property name
already matches a field the CatalogController declares by hand, the behavior **updates that existing field in
place** rather than replacing it — so a `config.add_facet_field` / `add_index_field` / `add_show_field` /
`add_search_field` naming a **literal Solr field** still depends on the profile producing that exact field
(same name, same suffix). If it doesn't, the pre-declared facet/column/search silently returns nothing — no
error.

Watch especially for **name mismatches between the property and the Solr field a pre-declared config
expects.** For example, the location field: the property is named `based_near` and indexes to `based_near_sim`
/ `based_near_tesim`, but the catalog facet/index/search reference **`based_near_label_*`** (a different field
produced by the `based_near` indexer via `render_term: based_near_label_tesim` in the profile). Removing
`based_near`, renaming it, or dropping its special indexing silently breaks the Location facet and search.

If you facet on a value backed by a hand-declared CatalogController entry, the profile **must** keep producing
the matching `_sim` field. The default profile does; if you edit indexing on those properties, keep the `_sim`
variant or the facet breaks.

### Fixed display config

`config.index.title_field = 'title_tesim'`, `config.index.display_type_field = 'has_model_ssim'`, and
`config.index.thumbnail_field = 'thumbnail_path_ss'` are hardcoded in the CatalogController template. The
search-results title always comes from `title_tesim` regardless of what the profile calls the title field.

### Behaviors the profile can never override

These are fixed in Hyrax code, not the profile:

- **`title` is always required** — `CoreMetadataValidator` forces `title` cardinality ≥ 1; you cannot make
  title optional through the profile.
- **`depositor`, `date_uploaded`, `date_modified` are system-set** — depositor is stamped from the current
  user; the dates are auto-populated. Declaring them in the profile controls their *display*, not their value.
- **`creator` on Admin Sets is hidden and set in a transaction** — the default profile declares a hidden
  `creator_hidden` (`name: creator`, `form: { display: false }`) on `AdminSetResource` for exactly this reason.
- **`schema_version` / `contexts`** are managed attributes on every flexible resource — not author-editable
  profile fields.
- **Compound rendering, redirect resolution, rich-text sanitization** follow their fixed renderers/controllers;
  the profile only opts a field in.

### View partials the profile can't restructure

The profile drives the **metadata table** on the show page (`base/_attribute_rows` iterating
`view_options_for`), the **form's metadata tab** (`primary_terms` / `secondary_terms` in
`base/_form_metadata`), and — in flexible mode — the **catalog columns/facets**. Everything *around* those
loops is fixed ERB. A property cannot move itself into, out of, or between these hardcoded regions, and several
fields are rendered by name *outside* the profile loop (so they appear whether or not the profile lists them,
and often in addition to their row in the metadata table).

**Show page** (`base/show.html.erb` and its partials):

- **Page skeleton is fixed order:** work-type tag → title → show actions → featured attributes → media →
  description → metadata table → compound cards → Relationships card → Items card. The profile cannot reorder
  these regions.
- **Title and description render by name near the top,** outside the metadata table:
  `base/_work_title.erb` renders `presenter.title` (with the permission and workflow badges);
  `base/_work_description.erb` renders `presenter.description`. Renaming or reordering `title`/`description` in
  the profile does not move these; it only affects their row in the metadata table (if still listed).
- **Embargo and lease dates are appended after the loop:** `base/_metadata.html.erb` renders
  `embargo_release_date` and `lease_expiration_date` (as `render_as: :date`) below the profile-driven rows,
  unconditionally.
- **`admin_set` is rendered in the Relationships card** (`base/_relationships_parent_rows.html.erb`, for
  logged-in users, `render_as: :faceted`), not from the profile.
- **The Items table columns are fixed** (`base/_items.html.erb` / `_member.html.erb`): thumbnail, title, date
  uploaded, visibility, actions. The profile cannot add or reorder member columns.
- **`base/_attributes.html.erb`** (the table variant that also hardcodes `permission_badge`, `license`, and
  member-of-collections rows) is used by the **single-use-links viewer**, not the default work show page — but
  it is another place where those rows sit outside the profile loop.

**Form** (`base/_form.html.erb` → `_guts4form` → tabs):

- **Tabs are hardcoded:** `metadata`, `files`, `relationships`, `share` (plus `redirects` when enabled), from
  `Hyrax::WorkFormHelper#form_tabs_for`. The profile cannot add, remove, or reorder tabs (a *developer* can, by
  overriding `form_tabs_for` and adding a `_form_<tab>` partial).
- **Only the metadata tab is profile-driven.** The files, relationships (admin set, collection membership),
  share (permissions), visibility/embargo/lease, and media (representative/thumbnail/rendering) sections are
  fixed partials the profile does not touch.
- **Primary vs. Additional-fields split is structural:** `form: { primary: true }` chooses the section, but the
  profile cannot collapse/expand behavior or put a secondary field in the always-visible region.

**FileSet show page** (`hyrax/file_sets/_metadata.html.erb`): the FileSet metadata is profile-driven, running
the same `view_options_for` loop as works (visible rows are split across two columns, and card compounds render
separately). As on the work show page, `embargo_release_date` / `lease_expiration_date` are appended after the
loop.

**Out-of-band field references** (never profile-driven on any surface):

- **Catalog search-result heading** is always `document.title_or_label`
  (`catalog/_index_header_list_default.html.erb`); the profile cannot use a different field as the result link.
- **Social / citation metatags** (`shared/_citations.html.erb`, `Hyrax::GoogleScholarPresenter`) read fixed
  fields — `title`, `description`, `keyword`, `rights_statement`, `creator`, `publisher`, dates, etc. Renaming
  those properties in the profile can *break* the metatags rather than relabel them.

The pattern to remember: **the profile controls the contents of a few specific loops, not the page or form
layout.** Anything a partial renders by calling `presenter.<field>` directly, or by rendering a fixed section
partial, is beyond the profile's reach and can only be changed by overriding the view.

### Where to look when something breaks

<details>
<summary>Symptom → likely cause → where to check (troubleshooting table)</summary>

| Symptom | Likely cause | Where to check |
|---|---|---|
| Sort option does nothing | sort targets an `_ssi`/`_dtsi` field the profile/indexer doesn't produce | `CatalogController` `add_sort_field` + the app's indexers |
| Facet missing (flexible mode) | property lacks the `facetable` token in `indexing:`, so `FlexibleCatalogBehavior` removed its `_sim` facet (the shipped default profile has *no* `facetable` tokens) | add `facetable` to the property's `indexing:` array |
| Facet missing / empty (pre-declared field) | a hand-declared `add_facet_field` names a `_sim`/`_ssim` (or `_label` variant) the profile doesn't produce | `CatalogController` `add_facet_field`; the property's `indexing:` and `render_term` |
| Column not in search results | property has `view: { search_results: false }`, or lacks `stored_searchable` / a `_tesim` key | the property's `view:` and `indexing:` |
| Field not searchable by fielded search | a pre-declared `add_search_field` targets a `_tesim` that's missing | `CatalogController` `add_search_field`; the property's `indexing:` |
| Profile reorder didn't move a catalog column/facet | that field is pre-declared in the CatalogController, so it keeps its controller position (only *non*-pre-declared fields follow profile order) | `CatalogController` `add_index_field`/`add_facet_field` for that field |
| Reorder had no effect on the form/show page | that order *is* profile-driven — check you edited the active profile version and restarted | profile `properties:` order; reseed + restart |
| Title/description won't move or hide on the show page | rendered by name outside the metadata loop | `base/_work_title.erb`, `base/_work_description.erb` (override the partial) |
| A field can't be added as a form tab/section | tabs and non-metadata sections are fixed partials | `WorkFormHelper#form_tabs_for` + `_form_<tab>` partials (developer task) |

</details>

**Baseline reference:** base Hyrax generator template at
`lib/generators/hyrax/templates/catalog_controller.rb`. Your own application's
`app/controllers/catalog_controller.rb` (generated from that template and then customized) is what actually
governs its catalog.

---

## Renaming / aliasing a property (`name:`)

The `name:` key decouples a property's **profile key** from the **resource attribute** it becomes. The loader
resolves the attribute as `config['name'] || <profile-key>`. Two uses:

1. Give a property a persisted name different from its YAML key (e.g. a hidden `creator` set only on admin
   sets, declared under a distinct profile key so it doesn't collide with the visible `creator`).
2. Set a member's key *inside* a compound, so two compounds can each carry (for example) a `title`.

```yaml
creator_hidden:      # profile key
  name: creator      # resolves to the `creator` attribute on the resource
  available_on: { class: [AdminSetResource] }
  form: { display: false }
```

Two standalone properties resolving to the **same** `name:` with overlapping class/context are rejected by
`FlexibleSchema#validate_property_name_conflicts`. (Reusing the same in-compound `name:` across *different*
compounds is allowed — that is how a subproperty is shared.)

---

## Contexts

Contexts let you show/hide fields based on the **Admin Set** a work belongs to — useful when different deposit
workflows need different metadata. Define a context, then reference it from a property's
`available_on.context`.

```yaml
contexts:
  special_context:
    display_label: Special Case Context   # shown in the Admin Set's Context dropdown
properties:
  abstract:
    available_on:
      class:
        - GenericWorkResource
      context:
        - special_context                 # must match the context key above
    display_label: { default: Abstract }
    property_uri: http://purl.org/dc/terms/abstract
    range: http://www.w3.org/2001/XMLSchema#string
```

To use a context: define it in the profile, reference it on the relevant properties, upload the profile,
create an Admin Set that selects the context, and any work created under that Admin Set uses the
context-filtered field set. A property with a `context` is skipped unless a matching context is active.

---

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

## Rich-text fields

A string property can be edited with a rich-text (WYSIWYG) editor and rendered as sanitized HTML. This works in both flexible and non-flexible mode and is driven by two independent directives:

- **`form: { input_type: rich_text }`** — the edit form renders the field through `records/edit_fields/_rich_text`, which emits a `<textarea class="rich-text">` (one per value; multi-valued fields keep the standard "Add another" control). `hyrax/rich_text_editor.js` attaches a **TinyMCE** WYSIWYG editor to every `textarea.rich-text` by default (tinymce-rails ships with Hyrax) and re-binds on the `managed_field:add` event so cloned rows become editors too. The `rich-text` class is also a clean override point — an app can attach a different editor — and with no JS the field degrades to a plain textarea.
- **`view: { render_as: html }`** — the show page renders the stored markup through `Hyrax::Renderers::HtmlAttributeRenderer`, which runs Rails' `sanitize` against a fixed tag/attribute allow-list (headings, lists, links, emphasis, tables; `href`/`title`/`target`/`rel`/`start`). Unsafe markup (`<script>`, `onclick`, …) is stripped at render time. This renderer owns its output, so it is unaffected by the `treat_some_user_inputs_as_markdown` Flipflop flag or any markdown decorator.

The editor stores HTML directly, so no markdown engine is involved. Sanitization happens at render time; applications may additionally sanitize on save as defense in depth.

`rich_text` is for free-text properties only. Declaring it on a controlled-vocabulary property (one whose `controlled_values.sources` names a real authority, a built-in controlled field such as `rights_statement`/`license`/`resource_type`, or a `type: controlled` compound subproperty) replaces the controlled input with a free-text editor and stores arbitrary HTML where a controlled value is expected. Saving such a profile raises a validation warning; see `Hyrax::FlexibleSchemaValidators::RichTextValidator`.

```yaml
# HYRAX_FLEXIBLE=false (config/metadata/*.yaml)
context_narrative:
  type: string
  multiple: false
  predicate: http://purl.org/dc/terms/description
  form:
    input_type: rich_text   # WYSIWYG (TinyMCE) editor on the edit form
  view:
    render_as: html         # sanitize + render the stored markup as HTML on the show page
```

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
  form:
    input_type: rich_text        # WYSIWYG (TinyMCE) editor on the edit form
  view:
    render_as: html              # render the stored markup as HTML (sanitized) on the show page
    search_results_truncate: 300 # optional; catalog snippet length, `false` to disable (default 230)
```

## Featured display

**`view: { position: featured }`** promotes a field out of the standard metadata table and renders it prominently near the top of the work show page:

- `field_visible?` returns false for a featured field (the same hook that hides `admin_only`/`editor_only` fields), so it is **not** duplicated in the attribute table.
- The `hyrax/base/_featured_attributes` partial renders every featured field above the metadata card. The default `hyrax/base/show.html.erb` includes this partial, so the directive works out of the box. Values are sanitized with the same allow-list as `Hyrax::Renderers::HtmlAttributeRenderer`, so a field that also declares `render_as: html` looks identical featured and in the table.

It pairs naturally with `render_as: html` for a rich-text "narrative" field, but works on any property:

```yaml
# add to either schema mode's `view:` block
  view:
    render_as: html        # optional: sanitize + render stored markup as HTML
    position: featured      # promote above the metadata table
```

Host applications that override `hyrax/base/show.html.erb` (or ship custom show themes) are responsible for rendering `<%= render 'featured_attributes', presenter: @presenter %>` wherever they want featured fields to appear; an override that omits it will simply not show them.

This is intentionally **not** covered by an m3 profile validator: the profile cannot know what an app's templates render.

## Related features

- **Compound (hierarchical) metadata**: an m3 profile (or YAML schema) can declare a `type: hash` property whose members are separate properties naming it via `available_on: { properties: [...] }` — repeatable groups of sub-fields such as `contributors`, `titles`, or `relationships`. Member sub-property types include `string`, `controlled`, `url`, `work_or_url`, and `linked_record` (a reference to a row in a database table, with an inline search-or-create picker). See [`documentation/compound_fields.md`](compound_fields.md) for declaring compounds, the supported sub-property types, indexing, and show-page rendering.
- **URL Redirects** (`HYRAX_REDIRECTS_ENABLED`): when enabled, the redirects feature requires a `redirects` property in the m3 profile (when also Flipflop-enabled). See [`documentation/redirects.md`](redirects.md) for the full schema and gating model.
- **Copy permalink button** (Flipflop `copy_permalink_button`): a show-page button that copies the record's canonical UUID-based URL. See [`documentation/copy_permalink.md`](copy_permalink.md).

---

## Schema versioning

- Uploading a profile creates a **new active schema** (a new `Hyrax::FlexibleSchema` row). The latest by
  `created_at` is active.
- Profiles are **never deleted** and cannot be restored in place — but you can download an older exported
  profile and re-upload it to revert.
- **Adding a field:** it appears on all new forms. Existing works keep their original schema version (stamped
  as `schema_version_ssi`) and remain valid until edited. If the new field is `required`, older works must be
  updated on next edit.
- **Removing a field:** it disappears from new forms. Existing works still display it until edited, after
  which they adopt the current schema and the field drops off.

---

## Admin UI

**Dashboard → Configuration → Metadata Profiles** (`Hyrax::Admin::MetadataProfilesController`):

- **index** — lists every stored profile (schema version, profile version = row id, type, created date), each
  with an export link.
- **import** — upload a YAML profile. Runs the full [validator suite](#what-is-required--what-makes-a-profile-invalid).
  Errors block the save and are flashed; warnings save the profile but flash a notice.
- **export** — download the current profile as YAML (stamps `version` and `date_modified`).

Routes: `resources :metadata_profiles, except: [:update, :show, :destroy]` with `post :import` and
`get :export`. There is intentionally no update or delete action — profiles are append-only and versioned.

**Permission.** Managing profiles is **admin-only**. `Hyrax::Ability::FlexibleMetadataAbility` grants
`can :manage, Hyrax::FlexibleSchema` only when the current user is an admin *and* `Hyrax.config.flexible?` is
true, and the controller renders under the admin dashboard layout. Non-admins cannot reach the Metadata
Profiles UI.

---

## Developer notes

### How it works behind the scenes

- Any class that inherits from `Hyrax::Resource` can be made flexible (Layer 2 above).
- A flexible class reads its schema through `Hyrax::Schema.m3_schema_loader` (`M3SchemaLoader`); a
  non-flexible class uses `Hyrax::Schema.simple_schema_loader` (`SimpleSchemaLoader`), which is the default
  for a `Hyrax::Schema(...)` include.
- The profile is stored as YAML in the `profile` column of the `hyrax_flexible_schemas` table; contexts are
  copied to the `contexts` column on save.
- Forms, indexers, and views read the active profile dynamically. A flexible resource applies its schema to
  its **singleton class** at load time (`Hyrax::Flexibility#load`), keyed by the resource's `schema_version`.

### Key services & models

<details>
<summary>Concern → file reference table</summary>

| Concern | File |
|---|---|
| Loader selection | `lib/hyrax/schema.rb` (`simple_schema_loader` / `m3_schema_loader`) |
| M3 loader (parses profile → attributes / form / index / view) | `app/services/hyrax/m3_schema_loader.rb` |
| Shared attribute/key resolution | `app/services/hyrax/schema_loader.rb` |
| Fixed-YAML loader | `app/services/hyrax/simple_schema_loader.rb` |
| Profile storage, versioning, m3→Hyrax key mapping | `app/models/hyrax/flexible_schema.rb` |
| Per-instance dynamic schema application | `app/models/concerns/hyrax/flexibility.rb` |
| Dynamic form schema + required-field validation (`property :contexts`) | `app/forms/concerns/hyrax/flexible_form_behavior.rb` |
| Sets `@latest_schema_version` on `new`/`edit` | `app/controllers/concerns/hyrax/flexible_schema_behavior.rb` |
| Auto-wires catalog columns/facets from the profile | `app/controllers/concerns/hyrax/flexible_catalog_behavior.rb` |
| Admin-only ability (`can :manage, Hyrax::FlexibleSchema`) | `app/models/concerns/hyrax/ability/flexible_metadata_ability.rb` |
| Validator orchestration | `app/services/hyrax/flexible_schema_validator_service.rb` |
| Individual validators | `app/services/hyrax/flexible_schema_validators/*.rb` |
| Structural JSON schema | `config/metadata_profiles/m3_json_schema.json` |
| Core-metadata requirements | `config/metadata/core_metadata.yaml` |
| Config flags | `lib/hyrax/configuration.rb` |
| Admin import/export | `app/controllers/hyrax/admin/metadata_profiles_controller.rb` |
| Seeds the default profile (`db:seed`, `first_or_create`) | `app/utils/hyrax/required_data_seeders/flexible_profile_seeder.rb` |
| DB table `hyrax_flexible_schemas` (`profile`, `contexts` text columns) | `db/migrate/*_create_hyrax_flexible_schemas.rb`, `*_add_contexts_to_hyrax_flexible_schemas.rb` |
| Indexing (writes `schema_version_ssi`, applies index rules) | `lib/hyrax/indexer.rb` |

</details>

### Which version rendered a work

Each work is indexed with `schema_version_ssi`. On display, the `M3SchemaLoader` resolves the matching
profile (`Hyrax::FlexibleSchema.find_by(id: version)`), so older works keep the fields and rendering they were
created with until edited.

### Background

Flexible metadata descends from a lineage of configurable-metadata tooling: **DogBiscuits** (metadata
scaffolding) → **ScoobySnacks** (YAML profiles) → **Houndstooth** (JSON-schema validation) → **Allinson
Flex** (editable classes, contexts, mappings, properties). The M3 profile system in Hyrax builds on Allinson
Flex to let repository managers customize metadata directly through a YAML file.
