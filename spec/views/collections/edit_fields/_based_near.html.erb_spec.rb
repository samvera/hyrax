# frozen_string_literal: true
RSpec.describe 'collections/edit_fields/_based_near.html.erb', type: :view do
  let(:collection) { Collection.new }
  let(:form) { Hyrax::Forms::CollectionForm.new(collection, nil, controller) }
  let(:form_template) do
    %(
      <%= simple_form_for @form, url: [hyrax, :dashboard, @form] do |f| %>
        <%= render "collections/edit_fields/based_near", f: f, key: 'based_near' %>
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
