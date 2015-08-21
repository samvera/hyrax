require 'spec_helper'

describe CurationConcerns::GenericFileAuditService do
  let(:f)       { FactoryGirl.create(:generic_file, content: File.open(fixture_file_path('world.png'))) }
  let(:service) { described_class.new(f) }

  describe '#audit' do
    context 'when a file has two versions' do
      before do
        CurationConcerns::VersioningService.create(f.original_file) # create a second version -- the factory creates the first version when it attaches +content+
      end
      subject { service.audit[f.original_file.id] }
      specify 'returns two log results' do
        expect(subject.length).to eq(2)
      end
    end
  end

  describe '#audit_file' do
    subject { service.send(:audit_file, f.original_file) }
    specify 'returns a single result' do
      expect(subject.length).to eq(1)
    end
  end

  describe '#audit_file_version' do
    subject { service.send(:audit_file_version, f.original_file.id, f.original_file.uri) }
    specify 'returns a single ChecksumAuditLog for the given file' do
      expect(subject).to be_kind_of ChecksumAuditLog
      expect(subject.generic_file_id).to eq(f.id)
      expect(subject.version).to eq(f.original_file.uri)
    end
  end

  describe '#audit_stat' do
    subject { service.send(:audit_stat, f.original_file) }
    context 'when no audits have been run' do
      it 'reports that audits have not been run' do
        expect(subject).to eq 'Audits have not yet been run on this file.'
      end
    end

    context 'when no audit is pasing' do
      before do
        CurationConcerns::VersioningService.create(f.original_file)
        ChecksumAuditLog.create!(pass: 1, generic_file_id: f.id, version: f.original_file.versions.first.uri, file_id: 'original_file')
      end

      it 'reports that audits have not been run' do
        expect(subject).to eq 'Some audits have not been run, but the ones run were passing.'
      end
    end
  end

  describe '#human_readable_audit_status' do
    context 'when audit_stat is 0' do
      subject { service.human_readable_audit_status 0 }
      it { is_expected.to eq 'failing' }
    end

    context 'when audit_stat is 1' do
      subject { service.human_readable_audit_status 1 }
      it { is_expected.to eq 'passing' }
    end

    context 'when audit_stat is something else' do
      subject { service.human_readable_audit_status 'something else' }
      it { is_expected.to eq 'something else' }
    end
  end
end
