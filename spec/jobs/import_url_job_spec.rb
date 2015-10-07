require 'spec_helper'

describe ImportUrlJob do
  let(:user) { create(:user) }

  let(:file_path) { fixture_path + '/world.png' }
  let(:file_hash) { '/673467823498723948237462429793840923582' }

  let(:file_set) do
    FileSet.new(import_url: "http://example.org#{file_hash}", label: file_path) do |f|
      f.apply_depositor_metadata(user.user_key)
    end
  end

  let(:file_set_id) { 'abc123' }
  let(:actor) { double }

  let(:mock_response) do
    double('response').tap do |http_res|
      allow(http_res).to receive(:start).and_yield
      allow(http_res).to receive(:content_type).and_return('image/png')
      allow(http_res).to receive(:read_body).and_yield(File.open(File.expand_path(file_path, __FILE__)).read)
    end
  end

  context 'after running the job' do
    before do
      allow(ActiveFedora::Base).to receive(:find).with(file_set_id).and_return(file_set)
      allow(CurationConcerns::FileSetActor).to receive(:new).with(file_set, user).and_return(actor)
    end

    it 'creates a content datastream' do
      expect_any_instance_of(Net::HTTP).to receive(:request_get).with(file_hash).and_yield(mock_response)
      expect(actor).to receive(:create_content).and_return(true)
      described_class.perform_now(file_set_id)
    end
  end
end
