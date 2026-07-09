# frozen_string_literal: true

# Renders the _compound_row partial with a `datepicker` sub-property and asserts
# it renders the native HTML5 date input (`<input type="date">`) pre-seeded with
# the stored ISO value. Exercises the `when 'datepicker'` branch.
RSpec.describe 'hyrax/compounds/_compound_row', type: :view do
  before do
    allow(view).to receive(:compound_subproperty_label).and_return('Start date')
    render partial: 'hyrax/compounds/compound_row',
           locals: { f:, compound_name: :dates, definition:,
                     row: { 'start_date' => '2025-03-01', 'note' => 'accepted' },
                     index: 0, row_label_singular: 'Date' }
  end

  # Minimal form builder against a throwaway object; the partial only uses
  # f.object_name for input names.
  let(:form_object) { Struct.new(:dates).new(nil) }
  let(:f) { ActionView::Helpers::FormBuilder.new('genericwork', form_object, view, {}) }

  let(:definition) do
    {
      subproperties: {
        'start_date' => { type: 'datepicker', cols: 6 },
        'note' => { type: 'string', cols: 6 }
      },
      groups: [{ label: nil, fields: %w[start_date note] }]
    }
  end

  it 'renders the datepicker sub-property as a native date input' do
    expect(rendered).to have_css("input[type=date][name='genericwork[dates_attributes][0][start_date]']")
  end

  it 'pre-seeds the date input with the stored ISO value' do
    input = Capybara.string(rendered).find("input[name='genericwork[dates_attributes][0][start_date]']")
    expect(input[:value]).to eq('2025-03-01')
  end

  it 'still renders sibling string sub-properties as text inputs' do
    expect(rendered).to have_css("input[type=text][name='genericwork[dates_attributes][0][note]']")
  end
end
