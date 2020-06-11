# frozen_string_literal: true
RSpec.describe 'records/edit_fields/_language.html.erb', type: :view do
  let(:work) { GenericWork.new }
  let(:form) { Hyrax::GenericWorkForm.new(work, nil, controller) }
  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "records/edit_fields/language", f: f, key: 'language' %>
      <% end %>
    )
  end

  before do
    assign(:form, form)
    render inline: form_template
  end

  it 'has url for autocomplete service' do
    expect(rendered).to have_selector('input[data-autocomplete-url="/authorities/search/local/languages"][data-autocomplete="language"]')
  end
end
