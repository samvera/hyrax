# frozen_string_literal: true
RSpec.describe 'hyrax/uploads/create.json.jbuilder' do
  let(:file) { double(filename: 'foo.jpg', size: 777) }
  let(:uploader) { instance_double(Hyrax::UploadedFileUploader, file: file) }
  let(:upload) { mock_model(Hyrax::UploadedFile, file: uploader) }

  before do
    assign(:upload, upload)
    render
  end

  it "renders json of the curation_concern" do
    json = JSON.parse(rendered).fetch('files').first
    expect(json['id']).to eq upload.id
    expect(json['name']).to eq 'foo.jpg'
    expect(json['deleteUrl']).to eq hyrax.uploaded_file_path(upload)
  end
end
