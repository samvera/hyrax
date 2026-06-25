# frozen_string_literal: true

# Renders the _compound_row partial with a `linked_record` sub-property and
# asserts the picker hidden input points at the generic QA authority (keyed by
# the source) and is pre-seeded with the resolved label, plus the inline
# lookup-or-create affordance built from `create_fields`. Exercises the
# `when 'linked_record'` branch and the _linked_record_field partial.
RSpec.describe 'hyrax/compounds/_compound_row', type: :view do
  # The source registration args the shared render uses. The default is a
  # fully-featured source (search + create) so the picker and inline
  # lookup-or-create UI render — matching the runtime contract a real source
  # provides. A context overrides `people_source` to register it differently
  # (e.g. without `search:`) before the shared render runs.
  let(:people_source) do
    { finder: ->(id) { id.to_s == '7' ? { id: 7 } : nil },
      label: ->(_r) { 'Ada Lovelace' },
      path: ->(_r) { '/people/7' },
      search: ->(_q) { [{ id: '7', label: 'Ada Lovelace', value: '7' }] },
      create: ->(attrs) { { id: 8, display_name: attrs[:display_name] } } }
  end

  before do
    Hyrax::CompoundLinkedRecordResolver.register(:people, **people_source)
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
                        { name: 'display_name', as: 'string', required: true, repeatable: false, values: nil, fields: nil },
                        { name: 'orcid', as: 'string', required: false, repeatable: false, values: nil, fields: nil },
                        { name: 'kind', as: 'select', required: false, repeatable: false, values: %w[person organization], fields: nil },
                        { name: 'identifiers', as: 'group', required: false, repeatable: true, values: nil,
                          fields: [
                            { name: 'value', as: 'string', required: false, repeatable: false, values: nil, fields: nil },
                            { name: 'scheme', as: 'select', required: false, repeatable: false, values: %w[ISNI ROR], fields: nil }
                          ] },
                        { name: 'affiliations', as: 'string', required: false, repeatable: true, values: nil, fields: nil }
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

    it 'renders the (hidden) Add new trigger naming the source item' do
      expect(rendered).to have_css('button[data-hyrax-linked-record-add]', text: 'Add a person', visible: false)
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

    describe 'a repeatable group create-field' do
      it 'renders a group container marked repeatable with an Add button' do
        expect(rendered).to have_css('[data-create-group="identifiers"][data-repeatable="true"]', visible: false)
        expect(rendered).to have_css('[data-create-group="identifiers"] button[data-create-group-add]', visible: false)
      end

      it 'renders an initial row with the sub-field inputs tagged data-create-subfield' do
        expect(rendered).to have_css('[data-create-group-rows] [data-create-group-row] input[data-create-subfield="value"]', visible: false)
        expect(rendered).to have_css('[data-create-group-rows] [data-create-group-row] select[data-create-subfield="scheme"]', visible: false)
      end

      it 'gives repeatable-row sub-field inputs no id (cloned rows must not collide on id)' do
        expect(rendered).to have_no_css('[data-create-group="identifiers"] [data-create-subfield][id]', visible: false)
      end

      it 'provides a row <template> for JS to clone' do
        expect(rendered).to have_css('[data-create-group="identifiers"] template[data-create-group-row-template]', visible: false)
      end
    end

    describe 'a repeatable scalar create-field' do
      it 'renders as add/remove rows marked data-create-scalar with one input per row' do
        expect(rendered).to have_css('[data-create-group="affiliations"][data-create-scalar="true"]', visible: false)
        expect(rendered).to have_css('[data-create-group="affiliations"] button[data-create-group-add]', visible: false)
        expect(rendered).to have_css('[data-create-group="affiliations"] [data-create-group-rows] input[data-create-subfield="affiliations"]', visible: false)
      end
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

  context 'when the source is not registered as searchable' do
    let(:definition) do
      {
        subproperties: { 'person' => { type: 'linked_record', authority: 'people', cols: 6, creatable: false, create_fields: [] } },
        groups: [{ label: nil, fields: %w[person] }]
      }
    end

    # Register `:people` without a `search:` proc (overriding the default) so the
    # shared render uses it. Without search the select2 picker has nothing to
    # query and (createSearchChoice is off) no way to enter a value, so the field
    # must fall back to a plain text input.
    let(:people_source) do
      { finder: ->(_id) {}, label: ->(_r) { '' }, path: ->(_r) { '' } }
    end

    it 'renders a plain text input and no select2 picker' do
      expect(rendered).to have_no_css('[data-hyrax-linked-record-input]')
      expect(rendered).to have_no_css('[data-hyrax-linked-record]')
      input = Capybara.string(rendered).find("input[name='genericwork[people_attributes][0][person]']", visible: :all)
      expect(input[:type]).to eq('text')
    end
  end
end
