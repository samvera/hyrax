# frozen_string_literal: true
RSpec.describe 'records/edit_fields/_description.html.erb', type: :view do
  let(:work) { GenericWork.new }
  let(:form) { Hyrax::GenericWorkForm.new(work, nil, controller) }
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
        expect(rendered).to have_selector('textarea[class="string multi_value optional generic_work_description form-control multi-text-field"]')
      end
    end

    context "when required" do
      before do
        expect(form).to receive(:required?).and_return(true)
      end
      it 'has text area' do
        render inline: form_template
        expect(rendered).to have_selector('textarea[class="string multi_value required generic_work_description form-control multi-text-field"]')
      end
    end
  end
end
