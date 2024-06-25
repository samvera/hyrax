# frozen_string_literal: true
RSpec.describe Hyrax::Statistics::FileSets::ByFormat, :clean_repo, valkyrie_adapter: :test_adapter, index_adapter: :solr_index do
  describe ".query" do
    let(:file1) { Rack::Test::UploadedFile.new('spec/fixtures/small_file.txt', 'text/plain') }
    let(:file2) { Rack::Test::UploadedFile.new('spec/fixtures/1.5mb-avatar.jpg', 'image/jpg') }
    let(:file3) { Rack::Test::UploadedFile.new('spec/fixtures/world.png', 'image/png') }
    let(:file4) { Rack::Test::UploadedFile.new('spec/fixtures/image.jpg', 'image/jpg') }
    let(:orig_file1) do
      Hyrax.persister.save(resource: Hyrax::FileMetadata.new(label: file1.original_filename,
                                                             original_filename: file1.original_filename,
                                                             mime_type: file1.content_type,
                                                             format_label: 'plain text'))
    end
    let(:orig_file2) do
      Hyrax.persister.save(resource: Hyrax::FileMetadata.new(label: file2.original_filename,
                                                             original_filename: file2.original_filename,
                                                             mime_type: file2.content_type,
                                                             format_label: 'JPEG image'))
    end
    let(:orig_file3) do
      Hyrax.persister.save(resource: Hyrax::FileMetadata.new(label: file3.original_filename,
                                                             original_filename: file3.original_filename,
                                                             mime_type: file3.content_type,
                                                             format_label: 'PNG image'))
    end
    let(:orig_file4) do
      Hyrax.persister.save(resource: Hyrax::FileMetadata.new(label: file4.original_filename,
                                                             original_filename: file4.original_filename,
                                                             mime_type: file4.content_type,
                                                             format_label: 'JPEG image'))
    end
    let(:fs1) { valkyrie_create(:hyrax_file_set, file_ids: [orig_file1.id]) }
    let(:fs2) { valkyrie_create(:hyrax_file_set, file_ids: [orig_file2.id]) }
    let(:fs3) { valkyrie_create(:hyrax_file_set, file_ids: [orig_file3.id]) }
    let(:fs4) { valkyrie_create(:hyrax_file_set, file_ids: [orig_file4.id]) }

    before { [fs1, fs2, fs3, fs4] }
    subject { described_class.query }

    it "is a list of categories" do
      [{ label: 'jpg (JPEG image)', data: 2 },
       { label: 'plain (plain text)', data: 1 },
       { label: 'png (PNG image)', data: 1 }].each do |set|
        item = subject.detect { |s| s.label == set[:label] }
        expect(item).to be
        expect(item.value).to eq(set[:data])
      end
    end
  end
end
