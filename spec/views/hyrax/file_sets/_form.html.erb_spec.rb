# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_form.html.erb', type: :view do
  let(:ability) { double }
  let(:file_set) { FileSet.new }
  let(:parent) { double('Work', human_readable_type: 'Work') }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(view).to receive(:curation_concern).and_return(file_set)
    allow_any_instance_of(ActionDispatch::Routing::RoutesProxy).to receive(:hyrax_file_sets_path).and_return('/file_set/1')
    allow(view).to receive(:parent_path).and_return('/work/1')
    assign(:parent, parent)

    # Transcript field
    allow(view).to receive(:render_transcript_ids_field?).and_return true
    allow(Hyrax::Forms::FileSetForm).to receive(:available_transcripts).and_return(
      [SolrDocument.new(id: "baz", title_tesim: "foo")]
    )

    render
  end

  it 'renders a title form field' do
    expect(rendered).to have_selector('input[name="file_set[title][]"]')
  end

  it 'renders a language form field' do
    expect(rendered).to have_selector('input[name="file_set[language][]"]')
  end

  it 'renders transcripts form' do
    expect(rendered).to have_select("file_set[transcript_ids][]", options: ["", "foo"])
    expect(rendered).to have_css("option[value='baz']", text: "foo")
  end

  it 'has submit button and cancel link' do
    expect(rendered).to have_selector('input.btn.btn-primary')
    expect(rendered).to have_selector('a.btn.btn-link', text: 'Cancel')
  end
end
