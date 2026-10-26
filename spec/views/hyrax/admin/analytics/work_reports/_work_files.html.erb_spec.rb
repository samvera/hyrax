# frozen_string_literal: true
RSpec.describe 'hyrax/admin/analytics/work_reports/_work_files.html.erb', type: :view do
  let(:document) { SolrDocument.new(id: 'work-1') }
  let(:file_document) { SolrDocument.new(id: 'file-1', title_tesim: ['A file']) }

  before do
    assign(:document, document)
    assign(:files, Kaminari.paginate_array(['file-1']).page(1))
    assign(:downloads, Hyrax::Analytics::Results.new([[Time.zone.today, 7]]))
    allow(SolrDocument).to receive(:find).with('file-1').and_return(file_document)
    allow(Hyrax::Analytics).to receive(:daily_events_for_id)
      .and_raise(Google::Cloud::PermissionDeniedError.new('analytics must not be called while rendering'))
  end

  it 'shows the download total the controller already loaded, without calling analytics' do
    render

    expect(rendered).to include('<td>7</td>')
    expect(Hyrax::Analytics).not_to have_received(:daily_events_for_id)
  end
end
