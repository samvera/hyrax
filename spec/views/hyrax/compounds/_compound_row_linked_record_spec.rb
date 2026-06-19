# frozen_string_literal: true

# Renders the _compound_row partial with a `linked_record` sub-property and
# asserts the picker hidden input points at the generic QA authority (keyed by
# the source) and is pre-seeded with the resolved label, plus the inline
# lookup-or-create affordance built from `create_fields`. Exercises the
# `when 'linked_record'` branch and the _linked_record_field partial.
RSpec.describe 'hyrax/compounds/_compound_row', type: :view do
  before do
    Hyrax::CompoundLinkedRecordResolver.register(
      :people,
      finder: ->(id) { id.to_s == '7' ? { id: 7 } : nil },
      label: ->(_r) { 'Ada Lovelace' },
      path: ->(_r) { '/people/7' }
    )
    allow(view).to receive(:compound_subproperty_label).and_return('Person')
    render partial: 'hyrax/compounds/compound_row',
           locals: { f:, compound_name: :people, definition:,
                     row: { 'person' => '7', 'role' => 'Author' },
                     index: 0, row_label_singular: 'Person' }
  end

  after { Hyrax::CompoundLinkedRecordResolver.registry.delete(:people) }

  # Minimal form builder against a throwaway object; the partial only uses
  # f.object_name for input names.
  let(:form_object) { Struct.new(:people).new(nil) }
  let(:f) { ActionView::Helpers::FormBuilder.new('genericwork', form_object, view, {}) }

  let(:definition) do
    {
      subproperties: {
        'person' => { type: 'linked_record', authority: 'people', cols: 6,
                      creatable: true,
                      create_fields: [
                        { name: 'display_name', as: 'string', required: true, values: nil },
                        { name: 'orcid', as: 'string', required: false, values: nil },
                        { name: 'kind', as: 'select', required: false, values: %w[person organization] }
                      ] },
        'role' => { type: 'string', cols: 6 }
      },
      groups: [{ label: nil, fields: %w[person role] }]
    }
  end

  it 'renders the linked_record value as a hidden picker input' do
    expect(rendered).to have_css(
      "input[type=hidden][name='genericwork[people_attributes][0][person]']", visible: false
    )
  end

  it 'points the picker autocomplete at the generic QA authority keyed by source' do
    expect(rendered).to match(%r{data-autocomplete-url="[^"]*/authorities/search/linked_record/people"})
  end

  it 'pre-seeds the picker label with the resolved record label' do
    expect(rendered).to match(/data-label="Ada Lovelace"/)
  end

  it 'still renders sibling string sub-properties as text inputs' do
    expect(rendered).to have_css("input[type=text][name='genericwork[people_attributes][0][role]']")
  end

  describe 'the inline create (lookup-or-create) affordance' do
    it 'renders the linked-record wrapper with source + create-url data' do
      expect(rendered).to have_css(
        'div[data-hyrax-linked-record][data-source="people"][data-creatable="true"]'
      )
      expect(rendered).to match(%r{data-create-url="[^"]*/linked_records/people"})
    end

    it 'renders the (hidden) Add new trigger' do
      expect(rendered).to have_css('button[data-hyrax-linked-record-add]', text: '+ Add new', visible: false)
    end

    it 'renders the create form fields from create_fields (string inputs + a select)' do
      expect(rendered).to have_css('[data-hyrax-linked-record-create-form] input[data-create-field="display_name"]', visible: false)
      expect(rendered).to have_css('[data-hyrax-linked-record-create-form] input[data-create-field="orcid"]', visible: false)
      expect(rendered).to have_css('[data-hyrax-linked-record-create-form] select[data-create-field="kind"]', visible: false)
    end

    it 'renders the select options from the field values' do
      expect(rendered).to have_css('select[data-create-field="kind"] option[value="person"]', visible: false)
      expect(rendered).to have_css('select[data-create-field="kind"] option[value="organization"]', visible: false)
    end
  end

  context 'when the sub-property is not creatable' do
    let(:definition) do
      {
        subproperties: { 'person' => { type: 'linked_record', authority: 'people', cols: 6, creatable: false, create_fields: [] } },
        groups: [{ label: nil, fields: %w[person] }]
      }
    end

    it 'renders no add-new trigger or create form' do
      expect(rendered).to have_no_css('[data-hyrax-linked-record-add]')
      expect(rendered).to have_no_css('[data-hyrax-linked-record-create-form]')
    end
  end
end
