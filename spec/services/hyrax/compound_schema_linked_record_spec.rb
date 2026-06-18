# frozen_string_literal: true

# A `linked_record` sub-property can declare profile-driven lookup-or-create:
# `creatable: true` plus `create_fields` describing the inline add-form, and
# `view: { label_field: }` naming which field of the resolved record supplies
# the show-page link text. `normalize_subproperty` returns a fixed key set and
# drops unknown keys, so these must be threaded through explicitly.
RSpec.describe Hyrax::CompoundSchema do
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      def self.name
        'TestLinkedRecordCompoundResource'
      end

      # A compound whose linked_record sub-property declares creatability, the
      # inline create-form field specs, and a label_field under `view:`.
      attribute :people,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: {
                    'person' => {
                      'type' => 'linked_record',
                      'authority' => 'people',
                      'view' => { 'label_field' => 'display_name' },
                      'creatable' => true,
                      'create_fields' => [
                        { 'name' => 'display_name', 'as' => 'string', 'required' => true },
                        { 'name' => 'orcid', 'as' => 'string' },
                        { 'name' => 'kind', 'as' => 'select', 'values' => %w[person organization] }
                      ]
                    },
                    'role' => { 'type' => 'controlled' }
                  }
                )

      # A second compound with a plain sub-property, to assert non-creatable defaults.
      attribute :titles,
                Valkyrie::Types::Array.of(Dry::Types['hash']).meta(
                  subproperties: { 'main' => { 'type' => 'string' } }
                )
    end
  end

  subject(:compound_schema) { described_class.for(resource_class) }

  let(:spec) { compound_schema.definition_for(:people)[:subproperties]['person'] }

  it 'carries creatable into the sub-property spec' do
    expect(spec[:creatable]).to be(true)
  end

  it 'normalizes create_fields with name/as/values/required' do
    expect(spec[:create_fields]).to eq(
      [
        { name: 'display_name', as: 'string', required: true, values: nil },
        { name: 'orcid', as: 'string', required: false, values: nil },
        { name: 'kind', as: 'select', required: false, values: %w[person organization] }
      ]
    )
  end

  it 'carries view.label_field into the sub-property spec' do
    expect(spec[:label_field]).to eq('display_name')
  end

  it 'defaults creatable to false, create_fields to [], label_field to nil when not declared' do
    s = compound_schema.definition_for(:titles)[:subproperties]['main']
    expect(s[:creatable]).to be(false)
    expect(s[:create_fields]).to eq([])
    expect(s[:label_field]).to be_nil
  end
end
