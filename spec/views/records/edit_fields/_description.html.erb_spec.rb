# frozen_string_literal: true
RSpec.describe 'records/edit_fields/_description.html.erb', type: :view do
  RSpec.shared_examples 'description field behaviors' do
    context "when single valued" do
      before do
        expect(form).to receive(:multiple?).and_return(false)
      end

      context "when not required" do
        before do
          expect(form).to receive(:required?).and_return(false)
        end
        it 'has text area' do
          render inline: form_template
          expect(rendered).to have_selector('textarea[class="form-control text optional"]')
        end
      end

      context "when required" do
        before do
          expect(form).to receive(:required?).and_return(true)
        end
        it 'has text area' do
          render inline: form_template
          expect(rendered).to have_selector('textarea[class="form-control text required"]')
        end
      end
    end

    context "when multi valued" do
      before do
        expect(form).to receive(:multiple?).and_return(true)
      end

      context "when not required" do
        before do
          expect(form).to receive(:required?).and_return(false)
        end
        it 'has text area' do
          render inline: form_template
          expect(rendered).to have_selector('textarea.string.multi_value.optional.form-control.multi-text-field')
        end
      end

      context "when required" do
        before do
          expect(form).to receive(:required?).and_return(true)
        end
        it 'has text area' do
          render inline: form_template
          expect(rendered).to have_selector('textarea.string.multi_value.required.form-control.multi-text-field')
        end
      end
    end
  end

  let(:form_template) do
    %(
      <%= simple_form_for [main_app, @form] do |f| %>
        <%= render "records/edit_fields/description", f: f, key: 'description' %>
      <% end %>
    )
  end

  before do
    assign(:form, form)
  end

  context 'ActiveFedora', :active_fedora do
    let(:work) { GenericWork.new }
    let(:form) { Hyrax::GenericWorkForm.new(work, nil, controller) }

    include_examples 'description field behaviors'
  end

  context 'Valkyrie' do
    let(:work) { Monograph.new }
    let(:form) do
      # Build a fresh form class with description field explicitly included,
      # to avoid dependency on MonographForm's class-level conditional state
      # which can vary based on test ordering.
      form_class = Class.new(Hyrax::Forms::ResourceForm) do
        self.model_class = Monograph
        include Hyrax::FormFields(:core_metadata)
        include Hyrax::FormFields(:basic_metadata)
      end
      form_class.new(resource: work)
    end

    include_examples 'description field behaviors'
  end
end
