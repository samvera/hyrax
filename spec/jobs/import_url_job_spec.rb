require 'spec_helper'

describe ImportUrlJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:file_path) { '/world.png' }
  let(:file_hash)  {'/673467823498723948237462429793840923582'}

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
      allow(http_res).to receive(:read_body).and_yield(File.open(File.expand_path('../../fixtures/world.png', __FILE__)).read)
    end
  end

  subject(:job) { ImportUrlJob.new(generic_file.id) }

  it "should have no content at the outset" do
    expect(generic_file.content.size).to be_nil
  end

  ### TODO - Needs Refactoring after Sufia is Broken up 
  # context "after running the job" do
  #   before do
  #     s1 = double('content deposit event')
  #     allow(ContentDepositEventJob).to receive(:new).with(generic_file.id, 'jilluser@example.com').and_return(s1).once
  #     expect(Sufia.queue).to receive(:push).with(s1).once
  #
  #     s2 = double('characterize')
  #     allow(CharacterizeJob).to receive(:new).with(generic_file.id).and_return(s2)
  #     expect(Sufia.queue).to receive(:push).with(s2).once
  #
  #     expect(Sufia::GenericFile::Actor).to receive(:virus_check).and_return(false)
  #   end
  #
  #   it "should create a content datastream" do
  #     expect_any_instance_of(Net::HTTP).to receive(:request_get).with(file_hash).and_yield(mock_response)
  #     job.run
  #     expect(generic_file.reload.content.size).to eq 4218
  #     expect(user.mailbox.inbox.first.last_message.body).to eq("The file (#{file_path}) was successfully imported.")
  #   end
  # end

  # context "when the file has a virus" do
  #   before do
  #     s1 = double('content deposit event')
  #     allow(ContentDepositEventJob).to receive(:new).with(generic_file.id, 'jilluser@example.com').never
  #
  #     s2 = double('characterize')
  #     allow(CharacterizeJob).to receive(:new).with(generic_file.id).never
  #   end
  #   it "should abort if virus check fails" do
  #     allow(Sufia::GenericFile::Actor).to receive(:virus_check).and_raise(Sufia::VirusFoundError.new('A virus was found'))
  #     job.run
  #     expect(user.mailbox.inbox.first.subject).to eq("File Import Error")
  #   end
  # end
end
