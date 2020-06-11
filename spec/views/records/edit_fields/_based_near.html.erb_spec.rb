# frozen_string_literal: true
RSpec.describe 'records/edit_fields/_based_near.html.erb', type: :view do
  let(:work) { GenericWork.new }
  let(:form) { Hyrax::GenericWorkForm.new(work, nil, controller) }
  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "records/edit_fields/based_near", f: f, key: 'based_near' %>
      <% end %>
    )
  end

  before do
    assign(:form, form)
    render inline: form_template
  end

  it 'has url for autocomplete service' do
    expect(rendered).to have_selector('input[data-autocomplete-url="/authorities/search/geonames"][data-autocomplete="based_near"]')
  end
end
