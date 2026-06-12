# frozen_string_literal: true

# Persist -> reload round-trip for the one compound shape the read-path repair
# (Hyrax::CompoundNormalization) cannot recover on its own: several one-field
# entries whose keys DIFFER.
#
# Valkyrie's Postgres read path (EnumeratorValue in JSONValueMapper) unwraps each
# single-key hash to its [key, value] pair before Hyrax sees the value, so
# [{name: 'Ada'}, {role: 'Editor'}] arrives as [[:name, 'Ada'], [:role, 'Editor']]
# - byte-identical to ONE entry {name:, role:} splayed apart. With distinct keys
# there is no signal left at the repair layer to tell the two origins apart, so
# the repair keeps the single-entry reading and the two people silently merge
# into one (the role misattributed to the wrong person).
#
# The only place that signal still exists is the conversion boundary itself,
# before the unwrap - i.e. Freyja/Frigg's ORMConverter. This spec drives a real
# persister save/reload (the merge does NOT reproduce through .new/.load alone)
# and expects both entries to survive. It is EXPECTED TO FAIL until a
# compound-scoped read override lands in the Hyrax adapter layer.
RSpec.describe 'compound distinct-key entries survive a persist/reload round-trip' do
  let(:profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }
  let(:test_profile) do
    YAML.safe_load(<<-YAML)
      classes:
        Hyrax::Test::CompoundRoundTrip::TestWork:
          display_label: Test Work
      properties:
        title:
          available_on:
            class: [Hyrax::Test::CompoundRoundTrip::TestWork]
        participants:
          type: hash
          data_type: array
          available_on:
            class: [Hyrax::Test::CompoundRoundTrip::TestWork]
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
  let(:schema) { Hyrax::FlexibleSchema.create(profile: profile.deep_merge(test_profile)) }

  before(:all) do
    module Hyrax::Test::CompoundRoundTrip
      class TestWork < Hyrax::Resource; end
    end
  end

  after(:all) do
    Hyrax::Test::CompoundRoundTrip.send(:remove_const, :TestWork)
  end

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    allow(Hyrax::FlexibleSchema).to receive(:find_by).and_return(schema)
    Hyrax::Test::CompoundRoundTrip::TestWork.acts_as_flexible_resource
  end

  after do
    allow(Hyrax.config).to receive(:flexible?).and_return(false)
  end

  it 'keeps two one-field entries with different keys as two separate entries' do
    work = Hyrax::Test::CompoundRoundTrip::TestWork.new(title: ['t'])
    work.participants = [{ 'name' => 'Ada' }, { 'role' => 'Editor' }]

    saved = Hyrax.persister.save(resource: work)
    reloaded = Hyrax.query_service.find_by(id: saved.id)

    expect(reloaded.participants).to eq([{ 'name' => 'Ada' }, { 'role' => 'Editor' }])
  end
end
