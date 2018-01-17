RSpec.describe Hyrax::RepositoryFixityCheckService do
  let!(:file) { create_for_repository(:file_set) }

  # The clean is here so that there is only one object that gets fixity checked
  describe "#fixity_check_everything", :clean_repo do
    it "fixity checks everything" do
      # make sure the fixity check gets called
      expect_any_instance_of(Hyrax::FileSetFixityCheckService).to receive(:fixity_check)
      described_class.fixity_check_everything
    end
  end
end
