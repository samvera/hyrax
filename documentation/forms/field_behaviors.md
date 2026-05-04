# Field Behaviors

A **Field Behavior** is a Ruby module mixed into `Hyrax::Forms::ResourceForm` (and its subclasses) that wires up a single property whose persisted shape and submitted-form shape differ. It owns the populator, prepopulator, and `deserialize!` strip for that property.

Use a Field Behavior when you have a property that:

- Is rendered through `accepts_nested_attributes_for` semantics (`<name>_attributes` payload from the form).
- Persists in a shape the view can't render directly (a hash of sub-fields, a URI string the view wants as a `ControlledVocabulary` instance, a triple of values, etc.).
- Needs the same wiring on every form subclass.

Two reference exemplars ship with Hyrax:

- `Hyrax::BasedNearFieldBehavior` — single-string-per-entry (URI), hydrated to a `ControlledVocabularies::Location` for the view.
- `Hyrax::RedirectsFieldBehavior` — multi-field-per-entry (path / canonical / sequence), hydrated to a `Hyrax::Redirect` presenter for the view.

This document covers the contract a Field Behavior must satisfy, the decision points for a new behavior, and the worked examples.

## Why this pattern exists

Reform's `FormBuilderMethods#deserialize!` rewrites the submitted `<name>_attributes` key to `<name>` before `from_hash` runs. If the form *also* has a property named `<name>` (e.g. from an `include Hyrax::Schema(:foo)`), Reform's `from_hash` writes the raw fragment hash onto the property — bypassing the populator entirely.

`deserialize!` is the right hook to fix this: by the time it runs, the rename has happened, but `from_hash` hasn't. A Field Behavior strips the renamed key from `params`, leaving the `<name>_attributes` payload as the only entry point. The populator then owns the write.

## The contract

A Field Behavior is a module that:

1. **Registers a virtual `<name>_attributes` property** in `self.included`, with a populator and prepopulator.

   ```ruby
   def self.included(descendant)
     descendant.property :<name>_attributes,
                         virtual: true,
                         populator: :<name>_attributes_populator,
                         prepopulator: :<name>_attributes_prepopulator
   end
   ```

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

4. **Provides a prepopulator** that hydrates the persisted value into a render-friendly object.

   ```ruby
   def <name>_attributes_prepopulator
     return unless respond_to?(:<name>)
     self.<name> = Array(<name>).map { |entry| MyPresenter.wrap(entry) }
   end
   ```

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
- **Multiple sub-fields per entry** (path + canonical + sequence; or label + value + lang): see `RedirectsFieldBehavior`.

### 2. Persisted as what?

- **Plain string / scalar** — fine for single-value entries.
- **Plain hash** with string keys — for multi-field entries. Add the `hash` shortcut to your YAML schema (`type: hash, multiple: true`). Use this *instead* of nesting a Valkyrie::Resource subclass; nested resources round-trip badly through Postgres JSONB (sub-fields strip, parent fields leak).

### 3. Does the view need a presenter?

- **Yes** if the view calls `.something` accessors on each entry. Build a small Ruby class with `path` / `value` / etc. readers and a `wrap(input)` class method that accepts both raw and already-wrapped input. The prepopulator wraps every entry; the view can rely on the presenter API.
- **No** if the view reads keys directly. Skip the presenter and let the view call `entry['key']`.

### 4. What happens to invalid input?

The populator drops empty rows and `_destroy` rows. Format validation belongs in an `ActiveModel::EachValidator` invoked by the form's `validation` block — *not* in the populator. The populator's job is shape conversion; the validator's job is correctness.

### 5. Is the property optional on some forms?

Always guard with `respond_to?(:<name>)` at the top of populator and prepopulator. Adopter forms whose models don't include the schema get a no-op rather than a crash.

## Exemplar: `BasedNearFieldBehavior`

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

## Exemplar: `RedirectsFieldBehavior`

```ruby
module Hyrax
  module RedirectsFieldBehavior
    def self.included(descendant)
      return unless Hyrax.config.redirects_enabled?
      descendant.property :redirects_attributes,
                          virtual: true,
                          populator: :redirects_attributes_populator,
                          prepopulator: :redirects_attributes_prepopulator
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
      entries = Array(fragment&.values)
                .reject { |row| row['_destroy'].to_s == 'true' || row['path'].to_s.strip.empty? }
                .each_with_index.map do |row, i|
        { 'path' => Hyrax::RedirectPathNormalizer.call(row['path']),
          'canonical' => row['canonical'].to_s == 'true',
          'sequence' => row['sequence'].presence&.to_i || i }
      end
      self.redirects = entries
    end

    def redirects_attributes_prepopulator
      return unless respond_to?(:redirects)
      return unless Hyrax.config.redirects_active?
      self.redirects = Array(redirects).map { |entry| Hyrax::Redirect.wrap(entry) }
    end
  end
end
```

- **Persisted shape:** array of plain hashes (`'path'`, `'canonical'`, `'sequence'`). Declared with `type: hash, multiple: true` in the YAML schema.
- **View-side shape:** array of `Hyrax::Redirect` presenters, exposing `.path` / `.canonical` / `.sequence`.
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

## Common pitfalls

- **Calling `from_hash` from inside `deserialize!`** — terminal. Breaks composition for any other behavior on the same form. Always call `super` and let Reform's base method do the rename + `from_hash`.
- **`include`-ing the behavior on subclasses** — the `included` callback runs but the `deserialize!` override doesn't take effect. Use `prepend` on subclasses so the override lands above the inherited method.
- **Conditional `prepend`** (`subclass.prepend(MyBehavior) if condition`) — the condition is evaluated at class-load time and never re-evaluated. Use unconditional `prepend` and gate inside the runtime methods.
- **Forgetting `respond_to?` guards** — adopter forms whose models don't include the schema raise `NoMethodError` instead of being a clean no-op.
- **Normalizing on read** — the persisted shape should be canonical so every consumer (validator, indexer, sync, importer) can compare without re-normalizing. Normalize in the populator (the form's write site) and add normalization to non-form write paths separately.
