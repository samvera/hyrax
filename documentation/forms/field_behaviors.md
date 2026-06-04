# Field Behaviors

A **Field Behavior** is a Ruby module mixed into `Hyrax::Forms::ResourceForm` (and its subclasses) that wires up a single property whose persisted shape and submitted-form shape differ. It owns the populator and the `deserialize!` strip for that property, and may optionally provide a prepopulator if the view needs a presenter wrapping each entry.

Use a Field Behavior when you have a property that:

- Is rendered through `accepts_nested_attributes_for` semantics (`<name>_attributes` payload from the form).
- Persists in a shape the view can't render directly (a hash of sub-fields, a URI string the view wants as a `ControlledVocabulary` instance, a triple of values, etc.).
- Needs the same wiring on every form subclass.

Two examples ship with Hyrax:

- `Hyrax::BasedNearFieldBehavior` — single-string-per-entry (URI), wrapped in a `ControlledVocabularies::Location` for the view.
- `Hyrax::RedirectsFieldBehavior` — multi-field-per-entry (path / is_display_url), wrapped in a `Hyrax::Redirect` presenter for the view.

This document covers the contract a Field Behavior must satisfy, the decision points for a new behavior, and the worked examples.

> **For new multi-sub-field compounds, prefer the generic, schema-driven path.**
> A field whose entries are a hash of named sub-fields (each an open-entry
> string or a controlled-vocabulary lookup) can be declared entirely in the
> schema YAML / m3 profile and rendered, populated, and indexed with no
> per-field Ruby or ERB — see [`compound_fields.md`](compound_fields.md). The
> hand-written Field Behaviors documented below remain the right tool for
> special cases: single-value-per-entry controlled URIs with a presenter
> (`based_near`), or compounds with bespoke behavior such as a radio-group
> selection, write-time normalization, global-uniqueness validation, or
> feature gating (`redirects`).

## Why this pattern exists

Reform's `FormBuilderMethods#deserialize!` rewrites the submitted `<name>_attributes` key to `<name>` before `from_hash` runs. If the form *also* has a property named `<name>` (e.g. from an `include Hyrax::Schema(:foo)`), Reform's `from_hash` writes the raw fragment hash onto the property — bypassing the populator entirely.

`deserialize!` is the right hook to fix this: by the time it runs, the rename has happened, but `from_hash` hasn't. A Field Behavior strips the renamed key from `params`, leaving the `<name>_attributes` payload as the only entry point. The populator then owns the write.

## The contract

A Field Behavior is a module that:

1. **Registers a virtual `<name>_attributes` property** in `self.included`, with a populator. Add a prepopulator if the view needs a presenter wrapping each persisted entry; otherwise the form partial can wrap entries inline at render time. If the persisted `<name>` property is not already on the form via some other include path, also load it from the corresponding YAML schema in `self.included` so the form partial can read `f.object.<name>` directly.

   ```ruby
   def self.included(descendant)
     descendant.include Hyrax::FormFields(:<name>)
     descendant.property :<name>_attributes,
                         virtual: true,
                         populator: :<name>_attributes_populator
   end
   ```

   Whether to load the persisted property depends on where the schema is included on application forms. `BasedNearFieldBehavior` skips this step because adopter forms include `Hyrax::FormFields(:basic_metadata)` directly, which already registers `based_near`. `RedirectsFieldBehavior` does not include the schema either; the persisted `redirects` property is provided by either the m3 loader (flexible mode) or by a per-class-level include on `ResourceForm` (non-flexible mode). Either way, when the schema is engine-level and not on a per-form include path, an extra `descendant.include Hyrax::FormFields(:<name>)` here is the third option.

2. **Composes via `super` in `deserialize!`**, then deletes its own renamed key.

   ```ruby
   def deserialize!(params)
     result = super
     if result.respond_to?(:delete)
       result.delete('<name>')
       result.delete(:<name>)
     end
     result
   end
   ```

   Calling `super` first lets every behavior in the chain run its own delete before control reaches Reform's base `deserialize!`. **Never** call `from_hash` yourself — that breaks composition for any behavior added later.

   Mutate `params` in place. Reform exposes the same hash via `form.input_params`; replacing it would orphan downstream readers.

3. **Provides a populator** that reads the `_attributes` fragment, normalizes to the persisted shape, and assigns to the property.

   ```ruby
   def <name>_attributes_populator(fragment:, **_options)
     return unless respond_to?(:<name>)
     # turn fragment into the persisted shape, then:
     self.<name> = entries
   end
   ```

   Drop empty rows and rows marked `_destroy` here. Normalize values here too — the persisted shape should be canonical so non-form callers (importers, console, validators) don't have to re-normalize.

4. **Optionally, provides a prepopulator** that wraps each persisted entry in a presenter the view can use. If you skip the prepopulator, the form partial can wrap entries inline at render time instead — useful when the view needs more control over which entries get wrapped or when wrapping should happen lazily.

   ```ruby
   def <name>_attributes_prepopulator
     return unless respond_to?(:<name>)
     self.<name> = Array(<name>).map { |entry| MyPresenter.wrap(entry) }
   end
   ```

   `BasedNearFieldBehavior` uses a prepopulator; `RedirectsFieldBehavior` wraps inline in the partial.

5. **Is `prepend`ed onto every subclass** in `ResourceForm.inherited`:

   ```ruby
   class << self
     def inherited(subclass)
       subclass.prepend(MyFieldBehavior)
       super
     end
   end
   ```

   `prepend` (not `include`) places the module's `deserialize!` *above* the subclass's own method on the ancestor chain, so it actually overrides. Each behavior gates itself internally and is a no-op when its property isn't on the subclass's model, so the unconditional prepend is safe.

## Feature-gated behaviors

If your behavior is tied to a feature flag (Flipflop, env config, etc.), gate **inside** the methods, not around the include / prepend:

```ruby
def self.included(descendant)
  return unless Hyrax.config.my_feature_enabled?
  descendant.include Hyrax::FormFields(:<name>)
  descendant.property ...
end

def deserialize!(params)
  result = super
  if Hyrax.config.my_feature_active? && result.respond_to?(:delete)
    result.delete('<name>')
    result.delete(:<name>)
  end
  result
end

def <name>_attributes_populator(fragment:, **_options)
  return unless respond_to?(:<name>)
  return unless Hyrax.config.my_feature_active?
  ...
end
```

The `self.included` gate uses the structural config (does this Hyrax build know about the feature at all?). The runtime methods use the combined gate (config + Flipflop) so the behavior turns off when an admin flips the feature off without restarting.

## Decision points

When adding a Field Behavior, work through these:

### 1. What does each entry look like?

- **Single value per entry** (URI string, scalar): see `BasedNearFieldBehavior`.
- **Multiple sub-fields per entry** (path + is_display_url; or label + value + lang): see `RedirectsFieldBehavior`.

### 2. Persisted as what?

- **Plain string / scalar** — fine for single-value entries.
- **Plain hash** with string keys — for multi-field entries. Add the `hash` shortcut to your YAML schema (`type: hash, multiple: true`). Use this *instead* of nesting a Valkyrie::Resource subclass; nested resources round-trip badly through Postgres JSONB (sub-fields strip, parent fields leak).

### 3. Does the view need a presenter?

- **Yes** if the view calls `.something` accessors on each entry. Build a small Ruby class with `path` / `value` / etc. readers and a `wrap(input)` class method that accepts both raw and already-wrapped input. Either the prepopulator wraps every entry up front (the `BasedNearFieldBehavior` pattern), or the form partial wraps entries inline at render time (the `RedirectsFieldBehavior` pattern). Either way the view code can rely on the presenter API.
- **No** if the view reads keys directly. Skip the presenter and let the view call `entry['key']`.

### 4. What happens to invalid input?

The populator drops empty rows and `_destroy` rows. Format validation belongs in an `ActiveModel::EachValidator` invoked by the form's `validation` block — *not* in the populator. The populator's job is shape conversion; the validator's job is correctness.

### 5. Is the property optional on some forms?

Always guard with `respond_to?(:<name>)` at the top of the populator (and the prepopulator, if you have one). Adopter forms whose models don't include the schema get a no-op rather than a crash.

## Example: `BasedNearFieldBehavior`

```ruby
module Hyrax
  module BasedNearFieldBehavior
    def self.included(descendant)
      descendant.property :based_near_attributes,
                          virtual: true,
                          populator: :based_near_attributes_populator,
                          prepopulator: :based_near_attributes_prepopulator
    end

    def deserialize!(params)
      result = super
      if result.respond_to?(:delete)
        result.delete('based_near')
        result.delete(:based_near)
      end
      result
    end

    private

    def based_near_attributes_populator(fragment:, **_options)
      return unless respond_to?(:based_near)
      adds, deletes = [], []
      fragment.each do |_, h|
        uri = RDF::URI.parse(h["id"]).to_s
        h["_destroy"] == "true" ? deletes << uri : adds << uri
      end
      self.based_near = ((model.based_near + adds) - deletes).uniq
    end

    def based_near_attributes_prepopulator
      return unless respond_to?(:based_near)
      self.based_near = based_near&.map { |loc| Hyrax::ControlledVocabularies::Location.new(RDF::URI.parse(loc)) }
      self.based_near ||= []
      self.based_near << Hyrax::ControlledVocabularies::Location.new if self.based_near.blank?
    end
  end
end
```

- **Persisted shape:** array of URI strings.
- **View-side shape:** array of `Hyrax::ControlledVocabularies::Location` instances.
- **Diff from a plain `_attributes` setup:** `deserialize!` strips `based_near` after the rename so `from_hash` doesn't overwrite the property with raw fragment hashes; the populator merges adds/removes onto the existing `model.based_near` so partial form submissions are non-destructive.

## Example: `RedirectsFieldBehavior`

```ruby
module Hyrax
  module RedirectsFieldBehavior
    def self.included(descendant)
      return unless Hyrax.config.redirects_enabled?
      # Declare the radio-group scalar before redirects_attributes so Reform
      # deserializes it first; the populator reads its value while building
      # per-row entries.
      descendant.property :redirects_display_url_index, virtual: true
      descendant.property :redirects_attributes,
                          virtual: true,
                          populator: :redirects_attributes_populator
    end

    def deserialize!(params)
      result = super
      if Hyrax.config.redirects_active? && result.respond_to?(:delete)
        result.delete('redirects')
        result.delete(:redirects)
      end
      result
    end

    private

    def redirects_attributes_populator(fragment:, **_options)
      return unless respond_to?(:redirects)
      return unless Hyrax.config.redirects_active?
      pairs = redirects_fragment_pairs(fragment)
      self.redirects = pairs.sort_by { |k, _row| k.to_i }
                            .map { |k, row| redirects_entry_from(k, row) }
                            .compact
    end
  end
end
```

The populator folds a sibling `redirects_display_url_index` scalar (a single radio-group value) into per-row `is_display_url` flags. When the index is unset (e.g. Bulkrax import), the row's own `is_display_url` value is honored.

- **Persisted shape:** array of plain hashes (`'path'`, `'is_display_url'`). Declared with `type: hash, multiple: true` in `config/metadata/redirects.yaml`.
- **View-side shape:** array of `Hyrax::Redirect` presenters, exposing `.path` and `.is_display_url`. The form partial wraps each persisted hash inline rather than via a prepopulator.
- **Diff from BasedNear:** entries carry multiple sub-fields, so the persisted shape is a hash rather than a string. The populator normalizes paths up front (canonical form lives in storage). The behavior is feature-gated — every callback consults `Hyrax.config.redirects_active?`.

## Wiring on `ResourceForm`

```ruby
module Hyrax
  module Forms
    class ResourceForm < Reform::Form
      include BasedNearFieldBehavior
      include RedirectsFieldBehavior

      class << self
        def inherited(subclass)
          subclass.prepend(BasedNearFieldBehavior)
          subclass.prepend(RedirectsFieldBehavior)
          super
        end
      end
    end
  end
end
```

Both behaviors compose. A subclass's ancestor chain ends up with both behaviors' `deserialize!` methods above Reform's base method; each runs its `super` then strips its own renamed key.

## Wiring up Bulkrax imports

Field Behaviors that strip their bare attribute key need a corresponding declaration on the Bulkrax import side. Bulkrax's CSV importer would otherwise write data under the bare attribute name (`redirects`) — which the form's `deserialize!` would strip — and the data would silently never reach the resource.

Bulkrax v9.5 and later supports a `nested_attributes: true` field-mapping flag for this case. When set alongside an `object:` value, Bulkrax routes the imported data to `parsed_metadata['<object>_attributes']` as a numbered-key hash with `_destroy: 'false'` per row — the same shape Reform's nested-attributes machinery expects, and the same shape this Field Behavior's populator consumes.

Example for `RedirectsFieldBehavior`:

```ruby
# In the host app's Bulkrax field-mapping configuration
'path'           => { from: ['redirect_path'],           object: 'redirects', nested_attributes: true },
'is_display_url' => { from: ['redirect_is_display_url'], object: 'redirects', nested_attributes: true }
```

CSV columns are `redirect_path_1`, `redirect_is_display_url_1`, `redirect_path_2`, `redirect_is_display_url_2`, …

Conventions:

- Declare `nested_attributes: true` on **every** sibling mapping that shares an `object:` value. Mixed-flag siblings produce undefined behavior.
- The mapping key (the hash key on the left of the `=>`) becomes the inner key on each entry. Keep it equal to the form populator's expected key (`'path'`, not `'redirect_path'`).
- Export side: Bulkrax reads the persisted attribute through its bare accessor (`record.redirects`). The flag has no effect on export — a single mapping declaration drives both directions.

Older `object:` mappings without the flag continue to land on `parsed_metadata['<object>']` as an array of plain hashes. The flag is opt-in.

`BasedNearFieldBehavior` predates the flag and is bridged via a hardcoded translator in `Bulkrax::ValkyrieObjectFactory#convert_based_near_to_attributes`. New Field Behaviors should declare the flag instead; samvera/bulkrax#1194 tracks deprecating that translator.

## Common pitfalls

- **Calling `from_hash` from inside `deserialize!`** — terminal. Breaks composition for any other behavior on the same form. Always call `super` and let Reform's base method do the rename + `from_hash`.
- **`include`-ing the behavior on subclasses** — the `included` callback runs but the `deserialize!` override doesn't take effect. Use `prepend` on subclasses so the override lands above the inherited method.
- **Conditional `prepend`** (`subclass.prepend(MyBehavior) if condition`) — the condition is evaluated at class-load time and never re-evaluated. Use unconditional `prepend` and gate inside the runtime methods.
- **Forgetting `respond_to?` guards** — adopter forms whose models don't include the schema raise `NoMethodError` instead of being a clean no-op.
- **Normalizing on read** — the persisted shape should be canonical so every consumer (validator, indexer, sync, importer) can compare without re-normalizing. Normalize in the populator (the form's write site) and add normalization to non-form write paths separately.
