# frozen_string_literal: true

# Renders the _compound_row partial with a `controlled` sub-property declaring
# `multiple: true` and `autocomplete: true`, asserting it renders a multi-select
# whose values submit as an array (`[]` name), pre-selects each stored value,
# and carries the select2 typeahead hook. Exercises the `when 'controlled'`
# branch's opt-in paths.
RSpec.describe 'hyrax/compounds/_compound_row', type: :view do
  before do
    allow(view).to receive(:compound_subproperty_label).and_return('Role')
    render partial: 'hyrax/compounds/compound_row',
           locals: { f:, compound_name: :credits, definition:,
                     row: { 'name' => 'Ada', 'role' => %w[author editor] },
                     index: 0, row_label_singular: 'Credit' }
  end

  let(:form_object) { Struct.new(:credits).new(nil) }
  let(:f) { ActionView::Helpers::FormBuilder.new('genericwork', form_object, view, {}) }

  let(:definition) do
    {
      subproperties: {
        'role' => { type: 'controlled', cols: 6, multiple: true, autocomplete: true,
                    authority: nil, values: [%w[Author author], %w[Editor editor], %w[Reviewer reviewer]] },
        'name' => { type: 'string', cols: 6 }
      },
      groups: [{ label: nil, fields: %w[role name] }]
    }
  end

  it 'renders a multiple select whose values submit as an array' do
    expect(rendered).to have_css("select[multiple][name='genericwork[credits_attributes][0][role][]']")
  end

  it 'tags the select for the select2 typeahead binder' do
    expect(rendered).to have_css("select[data-hyrax-compound-controlled][name='genericwork[credits_attributes][0][role][]']")
  end

  it 'pre-selects each stored value' do
    select = Capybara.string(rendered).find("select[name='genericwork[credits_attributes][0][role][]']")
    selected = select.all('option[selected]').map { |o| o[:value] }
    expect(selected).to contain_exactly('author', 'editor')
  end

  it 'offers every declared option' do
    select = Capybara.string(rendered).find("select[name='genericwork[credits_attributes][0][role][]']")
    expect(select.all('option').map { |o| o[:value] }).to include('author', 'editor', 'reviewer')
  end

  context 'a controlled sub-property with neither flag (backward compatible)' do
    let(:definition) do
      {
        subproperties: {
          'role' => { type: 'controlled', cols: 6, multiple: false, autocomplete: false,
                      authority: nil, values: [%w[Author author], %w[Editor editor]] },
          'name' => { type: 'string', cols: 6 }
        },
        groups: [{ label: nil, fields: %w[role name] }]
      }
    end

    before do
      render partial: 'hyrax/compounds/compound_row',
             locals: { f:, compound_name: :credits, definition:,
                       row: { 'name' => 'Ada', 'role' => 'author' },
                       index: 0, row_label_singular: 'Credit' }
    end

    it 'renders a plain single select with the scalar name (no [] suffix, no multiple)' do
      expect(rendered).to have_css("select[name='genericwork[credits_attributes][0][role]']")
      expect(rendered).to have_no_css("select[multiple][name='genericwork[credits_attributes][0][role]']")
      expect(rendered).to have_no_css('select[data-hyrax-compound-controlled]')
    end
  end
end
