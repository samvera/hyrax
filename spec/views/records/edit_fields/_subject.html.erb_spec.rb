# frozen_string_literal: true
RSpec.describe 'records/edit_fields/_subject.html.erb', type: :view do
  RSpec.shared_examples 'check for subject autocomplete url' do
    it 'has url for autocomplete service' do
      expect(rendered).to have_selector('input[data-autocomplete-url="/authorities/search/local/subjects"][data-autocomplete="subject"]')
    end
  end

  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "records/edit_fields/subject", f: f, key: 'subject' %>
      <% end %>
    )
  end

  before do
    assign(:form, form)
    render inline: form_template
  end

  context 'ActiveFedora', :active_fedora do
    let(:work) { GenericWork.new }
    let(:form) { Hyrax::GenericWorkForm.new(work, nil, controller) }

    include_examples 'check for subject autocomplete url'
  end

  context 'Valkyrie' do
    let(:work) { Monograph.new }
    let(:form) { Hyrax::Forms::ResourceForm.for(work) }

    include_examples 'check for subject autocomplete url'
  end
end
