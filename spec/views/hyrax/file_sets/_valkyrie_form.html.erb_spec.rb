# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_valkyrie_form.html.erb', type: :view do
  let(:ability) { double }
  let(:file_set) { Hyrax.config.file_set_class.new }
  let(:form) { Hyrax::Forms::ResourceForm.for(resource: file_set) }
  let(:curation_concern) { double('FileSet', flexible?: false, persisted?: true) }
  let(:parent) { double('Work', human_readable_type: 'Work') }

  before do
    skip 'Valkyrie only' if file_set.class < ActiveFedora::Base
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(view).to receive(:curation_concern).and_return(curation_concern)
    allow(view).to receive(:parent_path).and_return('/works/1')
    assign(:parent, parent)

    # Transcript field
    allow(view).to receive(:render_transcript_ids_field?).and_return true
    allow(Hyrax::Forms::FileSetForm).to receive(:valid_transcripts).and_return(
      [SolrDocument.new(id: "baz", title_tesim: "foo")]
    )

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

  it 'renders the form with file-set-form behavior and param-key data attributes' do
    expect(rendered).to have_selector('form[data-behavior="file-set-form"][data-param-key="file_set"]')
  end

  it 'renders based_near with autocomplete url' do
    expect(rendered).to have_selector('div[data-autocomplete-url="/authorities/search/geonames"][data-field-name="based_near"]')
  end

  it 'renders the transcripts form' do
    expect(rendered).to have_select("file_set[transcript_ids][]", options: ["", "foo"])
    expect(rendered).to have_css("option[value='baz']", text: "foo")
  end
end
