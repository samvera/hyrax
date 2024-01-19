# frozen_string_literal: true
RSpec.describe 'hyrax/base/_form_files.html.erb', type: :view do
  let(:model) { stub_model(GenericWork) }
  let(:form) { Hyrax.config.disable_wings ? Hyrax::Forms::ResourceForm.for(resource: model) : Hyrax::GenericWorkForm.new(model, double, controller) }
  let(:f) { double(object: form) }

  before do
    stub_template 'hyrax/uploads/_js_templates.html.erb' => 'templates'
    # TODO: stub_model is not stubbing new_record? correctly on ActiveFedora models.
    allow(model).to receive(:new_record?).and_return(false)
  end

  context "without browse_everything" do
    before do
      allow(Hyrax.config).to receive(:browse_everything?).and_return(false)
      render 'hyrax/base/form_files', f: f
    end

    it 'shows a message and buttons' do
      expect(rendered).to have_content 'You can add one or more files to associate with this work.'
      expect(rendered).to have_content('Add folder...')

      expect(rendered).not_to have_content 'cloud provider'
      expect(rendered).not_to have_selector('button#browse-btn')
    end
  end

  context "with browse_everything" do
    before do
      allow(Hyrax.config).to receive(:browse_everything?).and_return(true)
      render 'hyrax/base/form_files', f: f
    end

    it 'shows user timing warning' do
      expect(rendered).to have_content 'Note that if you use a cloud provider to upload a large number'
      expect(rendered).to have_selector("button[id='browse-btn'][data-target='#edit_generic_work_#{form.model.id}']")
    end
  end
end
