describe Sufia::RepositoryAuditService do
  let(:user) { FactoryGirl.create(:user) }
  let!(:file) do
    FileSet.create! do |file|
      file.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
      file.apply_depositor_metadata(user)
    end
  end

  describe "#audit_everything" do
    it "audits everything" do
      # make sure the audit gets called
      expect_any_instance_of(CurationConcerns::FileSetAuditService).to receive(:audit)
      described_class.audit_everything
    end
  end
end
