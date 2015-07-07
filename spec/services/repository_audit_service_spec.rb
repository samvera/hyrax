require 'spec_helper'

describe CurationConcerns::RepositoryAuditService do
  let(:user) { FactoryGirl.create(:user) }
  let!(:file) do
    GenericFile.create! do |file|
      file.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
      file.apply_depositor_metadata(user)
    end
  end

  describe "#audit_everything" do
    it "should audit everything" do
      expect_any_instance_of(GenericFile).to receive(:audit)
      CurationConcerns::RepositoryAuditService.audit_everything
    end
  end
end
