require 'spec_helper'

describe ImportUrlJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:file_path) { fixture_path + '/world.png' }
  let(:file_hash) { '/673467823498723948237462429793840923582' }

  let(:generic_file) do
    GenericFile.create do |f|
      f.import_url = "http://example.org#{file_hash}"
      f.label = file_path
      f.apply_depositor_metadata(user.user_key)
    end
  end

  let(:mock_response) do
    double('response').tap do |http_res|
      allow(http_res).to receive(:start).and_yield
      allow(http_res).to receive(:content_type).and_return('image/png')
      allow(http_res).to receive(:read_body).and_yield(File.open(File.expand_path(file_path, __FILE__)).read)
    end
  end

  subject(:job) { described_class.new(generic_file.id) }

  it 'has no content at the outset' do
    expect(generic_file.original_file).to be_nil
  end

  context 'after running the job' do
    before do
      s1 = double('characterize')
      allow(CharacterizeJob).to receive(:new).with(generic_file.id).and_return(s1)
      expect(CurationConcerns.queue).to receive(:push).with(s1).once
      expect(ClamAV.instance).to receive(:scanfile).and_return(0)
    end

    it 'creates a content datastream' do
      expect_any_instance_of(Net::HTTP).to receive(:request_get).with(file_hash).and_yield(mock_response)
      job.run
      expect(generic_file.reload.original_file.size).to eq 4218
    end
  end
end
