# frozen_string_literal: true
RSpec.describe 'hyrax/base/_form_rendering.html.erb', type: :view do
  let(:ability) { double }
  let(:work) { stub_model(GenericWork, new_record?: false) }
  let(:form) { Hyrax.config.disable_wings ? Hyrax::Forms::ResourceForm.for(resource: work) : Hyrax::GenericWorkForm.new(work, ability, controller) }

  let(:page) do
    view.simple_form_for form do |f|
      render 'hyrax/base/form_rendering', f: f
    end
    Capybara::Node::Simple.new(rendered)
  end

  before do
    allow(form).to receive(:select_files).and_return([{ '123' => 'File one' }])
  end

  it 'has a rendering_ids field' do
    expect(page).to have_selector("select#generic_work_rendering_ids", count: 1)
  end
end
