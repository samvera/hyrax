require 'spec_helper'

describe AuditJob do
  let(:user) { FactoryGirl.create(:user) }

  let(:file) do
    GenericFile.create do |file|
      file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      file.apply_depositor_metadata(user)
    end
  end

  let(:job) { AuditJob.new(file.id, 'content', uri) }

  describe "audit on content" do
    let(:uri) { file.content.uri }
    it "should pass" do
      expect(job.run).to eq(true)
    end
  end

  describe "audit on a version of the content" do
    let(:uri) { file.content.versions.first.uri }
    it "should pass" do
      expect(job.run).to eq(true)
    end
  end

  describe "audit on an invalid version of the content" do
    let(:uri) { file.content.versions.first.uri + "bogus" }
    it "should fail" do
      expect(job.run).to eq(false)
    end
  end

  describe "sending mail" do
    let(:uri) { file.content.uri }
    let(:inbox) { user.mailbox.inbox }

    before do
      allow_any_instance_of(ActiveFedora::FixityService).to receive(:check).and_return(result)
      job.run
    end

    context "when the audit passes" do
      let(:result) { true }
      it "should not send mail" do
        expect(inbox.count).to eq(0)
      end
    end
    context "when the audit fails" do
      let(:result) { false }
      it "should send failing mail" do
        expect(inbox.count).to eq(1)
        inbox.each { |msg| expect(msg.last_message.subject).to eq(AuditJob::FAIL) }
      end
    end
  end
end
