require 'spec_helper'

describe CurationConcerns::RepositoryAuditService do
  let(:user) { FactoryGirl.create(:user) }
  let!(:file) do
    fs = FileSet.create! do |f|
      f.apply_depositor_metadata(user)
    end
    Hydra::Works::AddFileToFileSet.call(fs, File.open(fixture_path + '/world.png'), :original_file)
    fs
  end

  describe '#audit_everything' do
    it 'audits everything' do
      expect_any_instance_of(FileSet).to receive(:audit)
      described_class.audit_everything
    end
  end
end
