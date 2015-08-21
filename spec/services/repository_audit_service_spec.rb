require 'spec_helper'

describe CurationConcerns::RepositoryAuditService do
  let(:user) { FactoryGirl.create(:user) }
  let!(:file) do
    gf = GenericFile.create! do |f|
      f.apply_depositor_metadata(user)
    end
    Hydra::Works::AddFileToGenericFile.call(gf, File.open(fixture_path + '/world.png'), :original_file)
    gf
  end

  describe '#audit_everything' do
    it 'audits everything' do
      expect_any_instance_of(GenericFile).to receive(:audit)
      described_class.audit_everything
    end
  end
end
