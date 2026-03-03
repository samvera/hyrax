# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_valkyrie_form.html.erb', type: :view do
  let(:ability) { double }
  let(:file_set) { Hyrax.config.file_set_class.new }
  let(:form) { Hyrax::Forms::ResourceForm.for(resource: file_set) }
  let(:curation_concern) { double('FileSet', flexible?: false, persisted?: true) }
  let(:parent) { double('Work', human_readable_type: 'Work') }

  before do
    skip 'Valkyrie only' if file_set.class < ActiveFedora::Base
    allow(view).to receive(:curation_concern).and_return(curation_concern)
    allow(view).to receive(:parent_path).and_return('/works/1')
    assign(:parent, parent)
    render partial: 'hyrax/file_sets/valkyrie_form', locals: { form_object: form }
  end

  it 'renders license as a select' do
    expect(rendered).to have_selector('select[name="file_set[license][]"]')
  end

  it 'renders multi-value fields with multi_value input' do
    expect(rendered).to have_selector('.multi_value')
  end

  it 'renders required fields with a required badge' do
    expect(rendered).to have_selector('label.required span.badge', text: 'required')
  end
end
