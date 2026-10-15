# frozen_string_literal: true

# Exercises the `when 'work_or_url'` branch and the _work_or_url_field partial.
RSpec.describe 'hyrax/compounds/_compound_row', type: :view do
  # Labels as itself by default, as the helper does for anything unresolved.
  # A context overrides this to stand in for a resolved work.
  let(:resolved_option) { [stored_value, stored_value] }

  before do
    allow(view).to receive(:compound_subproperty_label).and_return('Item')
    allow(view).to receive(:compound_work_or_url_option).and_return(resolved_option)
    render partial: 'hyrax/compounds/compound_row',
           locals: { f:, compound_name: :relationships, definition:,
                     row: { 'item' => stored_value, 'type' => 'References' },
                     index: 0, row_label_singular: 'Relationship' }
  end

  # Minimal form builder against a throwaway object; the partial only uses
  # f.object_name for input names.
  let(:form_object) { Struct.new(:relationships).new(nil) }
  let(:f) { ActionView::Helpers::FormBuilder.new('genericwork', form_object, view, {}) }
  let(:stored_value) { 'https://example.com/external' }

  let(:definition) do
    {
      subproperties: {
        'item' => { type: 'work_or_url', cols: 6 },
        'type' => { type: 'string', cols: 6 }
      },
      groups: [{ label: nil, fields: %w[item type] }]
    }
  end

  let(:input) { Capybara.string(rendered).find('input[name="genericwork[relationships_attributes][0][item]"]') }
  # Same field, found regardless of whether its wrapper is hidden.
  let(:hidden_input) do
    Capybara.string(rendered).find('input[name="genericwork[relationships_attributes][0][item]"]', visible: :all)
  end
  let(:url_wrap) { Capybara.string(rendered).find('[data-hyrax-compound-work-url-wrap]', visible: :all) }

  it 'submits through a visible text input, not a hidden one' do
    expect(input[:type]).to eq('text')
  end

  it 'pre-seeds the input with the stored value' do
    expect(input.value).to eq(stored_value)
  end

  it 'associates the rendered label with the submittable input' do
    label = Capybara.string(rendered).find('label[for]', match: :first)

    expect(input[:id]).to eq(label[:for])
  end

  describe 'the search picker' do
    let(:picker) { Capybara.string(rendered).find('[data-hyrax-compound-work-search]', visible: :all) }

    it 'points at the compound_works authority' do
      expect(picker['data-autocomplete-url']).to match(%r{/search/compound_works})
    end

    it 'targets the submittable input' do
      expect(picker['data-target']).to eq(input[:id])
    end

    it 'has no name, so it can never submit' do
      expect(picker[:name]).to be_blank
    end
  end

  context 'when the stored value resolves to an indexed work' do
    let(:stored_value) { 'abc123def' }
    let(:resolved_option) { ['Journal of Foo', stored_value] }

    it 'hides the URL field so the id is not displayed' do
      expect(url_wrap).not_to be_visible
    end

    it 'still submits the id' do
      expect(hidden_input.value).to eq('abc123def')
    end

    # select2 labels from data-label only when the element has a value; seeded with
    # nil it renders the placeholder and the work's title never appears.
    it 'seeds the picker so select2 can display the title' do
      picker = Capybara.string(rendered).find('[data-hyrax-compound-work-search]', visible: :all)

      expect(picker.value).to eq('abc123def')
      expect(picker['data-label']).to eq('Journal of Foo')
    end
  end

  # A scheme-less URL is neither an https:// URL nor a work, so a "not a URL" test
  # hid the field holding it — the value was invisible and uneditable.
  context 'when the stored value is a scheme-less URL' do
    let(:stored_value) { 'www.example.org/thing' }

    it 'keeps the field visible and editable' do
      expect(url_wrap).to be_visible
      expect(input.value).to eq(stored_value)
    end
  end

  context 'when the stored value is an id that no longer resolves' do
    let(:stored_value) { 'deleted-work-id' }

    it 'keeps the field visible' do
      expect(url_wrap).to be_visible
    end
  end

  it 'leaves the URL field visible when the value is a URL' do
    expect(url_wrap).to be_visible
  end

  it 'still renders a sibling string sub-property as a text input' do
    sibling = Capybara.string(rendered).find('input[name="genericwork[relationships_attributes][0][type]"]')

    expect(sibling[:type]).to eq('text')
  end
end
