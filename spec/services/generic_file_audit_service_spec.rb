require 'spec_helper'

describe CurationConcerns::GenericFileAuditService do
  let(:f)       { FactoryGirl.create(:generic_file, content: fixture_path + '/world.png' )}
  let(:service) { CurationConcerns::GenericFileAuditService.new(f) }

  describe "#audit" do
    context "when a file has two versions" do
      before do
        CurationConcerns::VersioningService.create(f.original_file)  # create a second version -- the factory creates the first version when it attaches +content+
      end
      subject { service.audit }
      specify "returns two log results" do
        expect(subject.length).to eq(2)
      end
    end
  end

  describe "#audit_file" do
    let(:file_to_audit) { f.original_file.versions.first }
    subject { service.send(:audit_file, "original_file", file_to_audit) }
    specify "returns a single ChecksumAuditLog for the given file" do
      expect(subject).to be_kind_of ChecksumAuditLog
      expect(subject.generic_file_id).to eq(f.id)
      expect(subject.version).to eq(file_to_audit.uri)
    end
  end

  describe "#audit_stat" do
    subject { service.send(:audit_stat) }
    context "when no audits have been run" do
      it "should report that audits have not been run" do
        expect(subject).to eq "Audits have not yet been run on this file."
      end
    end

    context "when no audit is pasing" do
      before do
        CurationConcerns::VersioningService.create(f.original_file)
        ChecksumAuditLog.create!(pass: 1, generic_file_id: f.id, version: f.original_file.versions.first.uri, dsid: 'original_file')
      end

      it "should report that audits have not been run" do
        expect(subject).to eq 1
      end
    end
  end

  describe "#human_readable_audit_status" do
    subject do
      expect(service).to receive(:audit_stat).and_return(audit_stat)
      service.human_readable_audit_status
    end

    context "when audit_stat is 0" do
      let(:audit_stat) { 0 }
      it { is_expected.to eq 'failing' }
    end

    context "when audit_stat is 1" do
      let(:audit_stat) { 1 }
      it { is_expected.to eq 'passing' }
    end

    context "when audit_stat is something else" do
      let(:audit_stat) { 'something else' }
      it { is_expected.to eq 'something else' }
    end
  end
end
