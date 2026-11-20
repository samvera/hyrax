# frozen_string_literal: true

# Exercises the layout of compound_field_lines in the rendered row.
RSpec.describe 'hyrax/compounds/_compound_row', type: :view do
  let(:form_object) { Struct.new(:contributors).new(nil) }
  let(:f) { ActionView::Helpers::FormBuilder.new('genericwork', form_object, view, {}) }

  # 4 + 4 + 6 overflows 12, so name and role share a line and note starts the next.
  let(:definition) do
    {
      subproperties: {
        'name' => { type: 'string', cols: 4 },
        'role' => { type: 'string', cols: 4 },
        'note' => { type: 'string', cols: 6 }
      },
      groups: [{ label: nil, fields: %w[name role note] }]
    }
  end

  before do
    allow(view).to receive(:compound_subproperty_label).and_return('Field')
    render partial: 'hyrax/compounds/compound_row',
           locals: { f:, compound_name: :contributors, definition:, row: nil,
                     index: 0, row_label_singular: 'Contributor' }
  end

  # In one shared .form-row the flexible col-md first field would let note wrap
  # up beside name and role, shrinking name to the leftover width.
  it 'renders each line in its own form row' do
    rows = Capybara.string(rendered).all('.form-row')

    expect(rows.map { |row| row.all('input[type="text"]').map { |input| input[:name][/\[(\w+)\]\z/, 1] } })
      .to eq([%w[name role], %w[note]])
  end
end
