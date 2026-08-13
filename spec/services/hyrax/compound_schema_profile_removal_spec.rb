# frozen_string_literal: true

# Removing a compound from the m3 profile must remove it from the form, without
# an app restart.
#
# The failure needs a specific boot order: the compound has to be present in the
# profile when the model class loads. `acts_as_flexible_resource` then bakes the
# compound parent into the CLASS schema, where it stays for the life of the
# process - `Hyrax::Flexibility.attributes` merges attributes in and has no way
# to express a removal. A later profile that omits the compound produces an
# attribute map without it, but `Hyrax::CompoundSchema.schema_sources_for`
# consults `resource.class.schema` as a fallback source, and that stale entry
# still carries the folded `subproperties:` in its Dry type meta - so the
# compound keeps resolving.
#
# An ordinary single-value property does NOT show this, which is why the bug
# reads as compound-specific: `ResourceForm#initialize` prunes any Reform
# definition absent from `form_definitions_for` at the current schema id, so a
# removed property like `abstract` stops rendering even while a stale key
# lingers in the Dry schema. Compounds never reach that prune - they render via
# `#compound_terms` (i.e. CompoundSchema), not through Reform's displayed
# definitions. The `abstract` example below is the control that pins this
# distinction.
RSpec.describe 'removing a compound from the m3 profile' do
  let(:base_profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }

  # The boot-time profile: declares the `participants` compound (a `type: hash`
  # parent with two members naming it via `available_on: { properties: }`) plus a
  # ordinary single-value property (`abstract`) to act as the control.
  let(:profile_with_compound) do
    base_profile.deep_merge(YAML.safe_load(<<-YAML))
      classes:
        Hyrax::Test::CompoundRemoval::TestWork:
          display_label: Test Work
      properties:
        title:
          available_on:
            class: [Hyrax::Test::CompoundRemoval::TestWork]
        abstract:
          type: string
          data_type: array
          form:
            primary: false
          available_on:
            class: [Hyrax::Test::CompoundRemoval::TestWork]
        participants:
          type: hash
          data_type: array
          form:
            primary: false
          available_on:
            class: [Hyrax::Test::CompoundRemoval::TestWork]
        participant_name:
          type: string
          name: name
          available_on:
            properties: [participants]
        participant_role:
          type: string
          name: role
          available_on:
            properties: [participants]
    YAML
  end

  # The replacement profile: same classes, but the compound parent, both of its
  # subproperties, and the control property are all gone.
  let(:profile_without_compound) do
    base_profile.deep_merge(YAML.safe_load(<<-YAML))
      classes:
        Hyrax::Test::CompoundRemoval::TestWork:
          display_label: Test Work
      properties:
        title:
          available_on:
            class: [Hyrax::Test::CompoundRemoval::TestWork]
    YAML
  end

  let(:schema_with_compound) { Hyrax::FlexibleSchema.create(profile: profile_with_compound) }
  let(:schema_without_compound) { Hyrax::FlexibleSchema.create(profile: profile_without_compound) }

  before(:all) do
    module Hyrax::Test::CompoundRemoval
      class TestWork < Hyrax::Resource; end
    end
  end

  after(:all) do
    Hyrax::Test::CompoundRemoval.send(:remove_const, :TestWork)
  end

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)

    # Boot the class against the profile that HAS the compound. This is the step
    # that seeds the class schema, and the step the working case never performs.
    activate(schema_with_compound)
    Hyrax::Test::CompoundRemoval::TestWork.acts_as_flexible_resource

    # Now swap in the profile without it - no class reload, no restart.
    activate(schema_without_compound)
  end

  after do
    allow(Hyrax.config).to receive(:flexible?).and_return(false)
  end

  # Point every schema-version lookup at one profile row. `current_schema_id` is
  # what the loader and ResourceForm read; `find_by` is what `resolve_schema`
  # uses; `order(...).pick(:id)` is what `Flexibility.load` defaults to when a
  # resource carries no schema_version.
  def activate(schema)
    allow(Hyrax::FlexibleSchema).to receive(:current_schema_id).and_return(schema.id)
    allow(Hyrax::FlexibleSchema).to receive(:find_by).and_return(schema)
    allow(Hyrax::FlexibleSchema).to receive(:order).and_return(
      instance_double(ActiveRecord::Relation, pick: schema.id, last: schema)
    )
  end

  let(:work) { Hyrax::Test::CompoundRemoval::TestWork.new(title: ['t']) }

  describe 'Hyrax::CompoundSchema' do
    it 'no longer reports the compound' do
      expect(Hyrax::CompoundSchema.for(work).compound_names).not_to include(:participants)
    end

    it 'no longer treats the removed attribute as a compound' do
      expect(Hyrax::CompoundSchema.for(work)).not_to be_compound(:participants)
    end
  end

  describe 'the work form' do
    let(:form) { Hyrax::Forms::ResourceForm.for(resource: work) }

    it 'does not offer the compound as a form term' do
      expect(form.compound_terms).not_to include(:participants)
    end

    it 'does not render the compound in the additional-fields section' do
      expect(form.secondary_compound_terms).not_to include(:participants)
    end

    # The control: an ordinary single-value property already disappears from the
    # form, via ResourceForm's prune of definitions absent from the current
    # profile. If this example ever fails alongside the compound ones, the cause
    # is broader than how CompoundSchema resolves its sources.
    it 'does not offer a removed single-value property as a form term' do
      expect(form.primary_terms + form.secondary_terms).not_to include(:abstract)
    end
  end
end
