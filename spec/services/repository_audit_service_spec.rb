require 'spec_helper'

describe CurationConcerns::RepositoryAuditService do
  let(:user) { FactoryGirl.create(:user) }
  let!(:file) do
    file = GenericFile.create! do |file|
      file.apply_depositor_metadata(user)
    end
    Hydra::Works::AddFileToGenericFile.call(file, File.open(fixture_path + '/world.png'), :original_file)
    file
  end

  describe "#audit_everything" do
    it "should audit everything" do
      expect_any_instance_of(GenericFile).to receive(:audit)
      CurationConcerns::RepositoryAuditService.audit_everything
    end
  end
end
