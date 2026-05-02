# Form Field Behaviors

A **Field Behavior** is a Ruby module that owns the form-side handling for one nested-attribute property on `Hyrax::Forms::ResourceForm` (and its subclasses). When a Hyrax adopter's form posts a nested-attribute payload like `redirects_attributes` or `based_near_attributes`, a Field Behavior is what turns that payload into clean values on the underlying resource.

This document describes the contract every Field Behavior must follow, why the contract is shaped this way, and how to add a new one.

## When you need a Field Behavior

You need a Field Behavior when **all three** of these are true:

1. The property holds a list of nested entries — e.g., a list of redirect rows, a list of `ControlledVocabularies::Location` URIs.
2. The form posts under `<name>_attributes` (the Rails nested-attributes convention) and the populator needs to convert that index-keyed payload into clean entries.
3. A property by `<name>` is also declared on the form (e.g., from a Valkyrie schema include or an m3 metadata profile). Without #3, a virtual property + populator is enough; a Field Behavior is overkill.

The third condition is the one that makes a Field Behavior necessary. When `<name>` is a real form property, some preprocessing between the controller and the form copies `<name>_attributes` to `<name>` alongside in the params hash. Reform's `from_hash` then writes `params['<name>']` directly into `@fields["<name>"]` via Disposable's internal `field_write`, **bypassing both** the public `<name>=` setter and the virtual `<name>_attributes` populator. The form ends up with a raw `ActionController::Parameters` value where it expected a list of entries, and validation crashes.

The Field Behavior's job is to **strip the duplicate `<name>` key from incoming params** before Reform's `from_hash` runs. The populator on `<name>_attributes` then becomes the single entry point for form-driven writes.

## The contract

Every Field Behavior must:

### 1. Declare the virtual `_attributes` property in `self.included(descendant)`

```ruby
def self.included(descendant)
  descendant.property :foo_attributes, virtual: true, populator: :foo_attributes_populator
end
```

Optional: pass `prepopulator:` if the values stored on the model aren't directly renderable by the form widget and need to be wrapped first. For example, `based_near` is stored as plain URI strings on the model, but the location widget expects `Hyrax::ControlledVocabularies::Location` instances; the prepopulator wraps the strings into those objects before render. `BasedNearFieldBehavior` does this; `RedirectsFieldBehavior` does not (a `Hyrax::Redirect` is already what the redirects widget renders directly).

### 2. Override `deserialize(params)` to strip the duplicate key in place, **then call `super`**

```ruby
def deserialize(params)
  if params.respond_to?(:delete)
    params.delete('foo')
    params.delete(:foo)
  end
  super
end
```

**Mutate `params` in place; do not replace it.** Reform's `validate(params)` saves the incoming hash as `@input_params` and exposes it via `form.input_params`. Downstream code (e.g., `WorksControllerBehavior` reading `form.input_params["permissions"]`) reads from that same hash *after* Reform's `FormBuilderMethods#deserialize!` mutates it in place to translate `<name>_attributes` keys to `<name>`. If your Field Behavior reassigns `params = params.except(...)`, the rename happens on a local copy and the controller sees an unrenamed `@input_params`, silently breaking permissions and other nested-attribute reads.

Delete both the string and symbol form. `ActionController::Parameters#delete` is key-form-agnostic, but a plain `Hash` with symbol keys is not — deleting both keeps unit tests that pass a symbol-keyed hash and production controllers that pass string-keyed `Parameters` symmetric.

**Always call `super`.** Reform's base `Reform::Form::Validate#deserialize` is the natural terminus — it runs `deserialize!` (the `<name>_attributes` rename) and `deserializer.new(self).from_hash(params)` after every Field Behavior in the prepend chain has deleted its key. Calling `from_hash` directly inside your override would short-circuit other Field Behaviors that should have run first.

The `respond_to?(:delete)` guard is defensive — `params` is usually `ActionController::Parameters` or `Hash`, both of which respond to `delete`, but a hand-rolled deserializer test might pass something else.

### 3. Implement the populator as a private instance method

The populator's name matches the symbol you passed to `populator:` in step 1.

```ruby
private

def foo_attributes_populator(fragment:, **_options)
  return unless respond_to?(:foo)  # form's underlying resource must have :foo
  entries = Array(fragment&.values)
            .reject { |row| row['_destroy'].to_s == 'true' }
            .map    { |row| build_foo_entry(row) }
  self.foo = entries
end
```

The `respond_to?(:foo)` guard is important — adopters may inherit from `ResourceForm` for resources that don't have the property (e.g., a deployment's custom work class that doesn't include the redirects schema). Without the guard, the populator crashes when invoked on those forms.

### 4. Wire it onto `ResourceForm` in two places

```ruby
# app/forms/hyrax/forms/resource_form.rb

class ResourceForm < Hyrax::ChangeSet
  include FooFieldBehavior  # so self.included fires and declares the virtual property

  class << self
    def inherited(subclass)
      subclass.prepend(BasedNearFieldBehavior)
      subclass.prepend(FooFieldBehavior)  # so deserialize override lands on every subclass
      super
    end
  end
end
```

Both wirings are required. `include` makes the `_attributes` virtual property available; `prepend` (inside `inherited`) makes the `deserialize` override take precedence over Reform's base method.

## Why `super` matters: the chain composes

Each prepended Field Behavior sits above the form class in the ancestor chain, in declaration order. When the controller calls `form.validate(params)`:

1. The outermost Field Behavior's `deserialize(params)` runs first.
2. It strips its key and calls `super`.
3. The next Field Behavior down the chain runs, strips *its* key, calls `super`.
4. Eventually Reform's base `deserialize` runs with all keys stripped, calls `from_hash` once, and writes only the surviving (clean, non-duplicated) keys to the form.

This means **adding a new Field Behavior is purely additive**. Write the module, include it on `ResourceForm`, prepend it in `inherited`. You don't need to know about prior Field Behaviors. The chain takes care of itself.

If a Field Behavior breaks the chain by *not* calling `super`, every Field Behavior below it stops working. Always call `super`.

## Worked examples

### `BasedNearFieldBehavior`

```ruby
# app/forms/concerns/hyrax/based_near_field_behavior.rb
module Hyrax
  module BasedNearFieldBehavior
    def self.included(descendant)
      descendant.property :based_near_attributes,
                          virtual: true,
                          populator: :based_near_attributes_populator,
                          prepopulator: :based_near_attributes_prepopulator
    end

    def deserialize(params)
      if params.respond_to?(:delete)
        params.delete('based_near')
        params.delete(:based_near)
      end
      super
    end

    private

    def based_near_attributes_populator(fragment:, **_options)
      return unless respond_to?(:based_near)
      adds = []
      deletes = []
      fragment.each do |_, h|
        uri = RDF::URI.parse(h["id"]).to_s
        h["_destroy"] == "true" ? deletes << uri : adds << uri
      end
      self.based_near = ((model.based_near + adds) - deletes).uniq
    end

    def based_near_attributes_prepopulator
      # Hydrate URIs into widget-friendly Location objects on form render.
      # ...
    end
  end
end
```

### `RedirectsFieldBehavior`

```ruby
# app/forms/concerns/hyrax/redirects_field_behavior.rb
module Hyrax
  module RedirectsFieldBehavior
    def self.included(descendant)
      return unless Hyrax.config.redirects_enabled?
      descendant.property :redirects_attributes, virtual: true, populator: :redirects_populator
    end

    def deserialize(params)
      if Hyrax.config.redirects_enabled? && params.respond_to?(:delete)
        params.delete('redirects')
        params.delete(:redirects)
      end
      super
    end

    private

    def redirects_populator(fragment:, **_options)
      return unless respond_to?(:redirects)
      return unless Flipflop.redirects?
      entries = Array(fragment&.values)
                .reject { |row| row['_destroy'].to_s == 'true' || row['path'].to_s.strip.empty? }
                .map    { |row| { path: row['path'], canonical: row['canonical'].to_s == 'true' } }
      self.redirects = entries
    end
  end
end
```

The two modules differ only in feature-gating (`Hyrax.config.redirects_enabled?` / `Flipflop.redirects?`) and in whether they have a prepopulator. The shape is otherwise identical.

## Checklist for adding a new Field Behavior

1. [ ] Module defines `self.included(descendant)` declaring the `<name>_attributes` virtual property.
2. [ ] Module defines `deserialize(params)` that strips `<name>` and calls `super`.
3. [ ] Module defines a private populator named after the property's `populator:` symbol.
4. [ ] Populator guards `respond_to?(:<name>)` for forms whose model lacks the property.
5. [ ] Populator handles the `_destroy` flag for row removal.
6. [ ] If feature-gated, the gate appears in `self.included`, `deserialize`, AND the populator.
7. [ ] `ResourceForm` does both `include FooFieldBehavior` AND `subclass.prepend(FooFieldBehavior)` inside `inherited`.
8. [ ] Optional: `prepopulator:` if the values stored on the model need to be wrapped into a different shape before the form widget can render them.
