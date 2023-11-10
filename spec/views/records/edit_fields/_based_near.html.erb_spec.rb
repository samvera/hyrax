# frozen_string_literal: true
RSpec.describe 'records/edit_fields/_based_near.html.erb', type: :view do
  RSpec.shared_examples 'check for based_near autocomplete url' do
    it 'has url for autocomplete service' do
      expect(rendered).to have_selector('input[data-autocomplete-url="/authorities/search/geonames"][data-autocomplete="based_near"]')
    end
  end

  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "records/edit_fields/based_near", f: f, key: 'based_near' %>
      <% end %>
    )
  end

  before do
    assign(:form, form)
    form.prepopulate! if form.is_a?(Valkyrie::ChangeSet)
    render inline: form_template
  end

  context 'ActiveFedora', :active_fedora do
    let(:work) { GenericWork.new }
    let(:form) { Hyrax::GenericWorkForm.new(work, nil, controller) }

    include_examples 'check for based_near autocomplete url'
  end

  context 'Valkyrie' do
    let(:work) { Monograph.new }
    let(:form) { Hyrax::Forms::ResourceForm.for(work) }

    include_examples 'check for based_near autocomplete url'
  end
end
