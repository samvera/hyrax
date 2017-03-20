require 'spec_helper'

describe ImportUrlJob do
  let(:user) { create(:user) }

  let(:file_path) { fixture_path + '/world.png' }
  let(:file_hash) { '/673467823498723948237462429793840923582' }

  let(:file_set) do
    FileSet.new(import_url: "http://example.org#{file_hash}",
                label: file_path) do |f|
      f.apply_depositor_metadata(user.user_key)
    end
  end

  let(:operation) { create(:operation) }
  let(:success_service) { instance_double(Hyrax::ImportUrlSuccessService) }
  let(:actor) { instance_double(Hyrax::Actors::FileSetActor, create_content: true) }

  before do
    allow(Hyrax::ImportUrlSuccessService).to receive(:new).and_return(success_service)
    allow(Hyrax::Actors::FileSetActor).to receive(:new).with(file_set, user).and_return(actor)

    stub_request(:get, "http://example.org#{file_hash}").to_return(
      body: File.open(File.expand_path(file_path, __FILE__)).read, status: 200, headers: { 'Content-Type' => 'image/png' }
    )
  end

  context 'after running the job' do
    before do
      file_set.id = 'abc123'
      allow(file_set).to receive(:reload)
    end

    it 'creates the content and updates the associated operation' do
      expect(success_service).to receive(:call)
      expect(actor).to receive(:create_content).with(Tempfile, 'original_file', false).and_return(true)
      described_class.perform_now(file_set, operation)
      expect(operation).to be_success
    end
  end

  context "when a batch update job is running too" do
    let(:title) { { file_set.id => ['File One'] } }
    let(:metadata) { {} }
    let(:visibility) { nil }
    let(:file_set_id) { file_set.id }

    before do
      file_set.save!
      allow(ActiveFedora::Base).to receive(:find).and_call_original
      allow(ActiveFedora::Base).to receive(:find).with(file_set_id).and_return(file_set)
      # run the batch job to set the title
      file_set.update(title: ['File One'])
    end

    it "does not kill all the metadata set by other processes" do
      expect(success_service).to receive(:call)

      # run the import job
      described_class.perform_now(file_set, operation)

      # import job should not override the title set another process
      file = FileSet.find(file_set_id)
      expect(file.title).to eq(['File One'])
    end
  end
end
