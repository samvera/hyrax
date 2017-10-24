RSpec.describe 'records/edit_fields/_based_near.html.erb', type: :view do
  let(:work) { GenericWork.new }
  let(:change_set) { GenericWorkChangeSet.new(work) }
  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @change_set] do |f| %>
        <%= render "records/edit_fields/based_near", f: f, key: 'based_near' %>
      <% end %>
    )
  end

  before do
    assign(:change_set, change_set)
    render inline: form_template
  end

  it 'has url for autocomplete service' do
    expect(rendered).to have_selector('input[data-autocomplete-url="/authorities/search/geonames"][data-autocomplete="based_near"]')
  end
end
