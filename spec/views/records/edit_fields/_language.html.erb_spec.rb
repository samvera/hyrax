# frozen_string_literal: true
RSpec.describe 'records/edit_fields/_language.html.erb', type: :view do
  RSpec.shared_examples 'check for language autocomplete url' do
    it 'has url for autocomplete service' do
      expect(rendered).to have_selector('input[data-autocomplete-url="/authorities/search/local/languages"][data-autocomplete="language"]')
    end
  end

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

  context 'ActiveFedora', :active_fedora do
    let(:work) { GenericWork.new }
    let(:form) { Hyrax::GenericWorkForm.new(work, nil, controller) }

    include_examples 'check for language autocomplete url'
  end

  context 'Valkyrie' do
    let(:work) { Monograph.new }
    let(:form) do
      # Build a fresh form class with language field explicitly included,
      # to avoid dependency on MonographForm's class-level conditional state
      # which can vary based on test ordering.
      form_class = Class.new(Hyrax::Forms::ResourceForm) do
        self.model_class = Monograph
        include Hyrax::FormFields(:core_metadata)
        include Hyrax::FormFields(:basic_metadata)
      end
      form_class.new(resource: work)
    end

    include_examples 'check for language autocomplete url'
  end
end
