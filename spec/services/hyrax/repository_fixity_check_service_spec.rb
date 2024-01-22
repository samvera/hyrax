# frozen_string_literal: true

# NOTE: This service is only optimized to process ActiveFedora objects.
RSpec.describe Hyrax::RepositoryFixityCheckService, :active_fedora do
  let!(:file) do
    create(:file_set).tap do |file|
      file.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
    end
  end

  # The clean is here so that there is only one object that gets fixity checked
  describe "#fixity_check_everything", :clean_repo do
    it "fixity checks everything" do
      # make sure the fixity check gets called
      expect_any_instance_of(Hyrax::FileSetFixityCheckService).to receive(:fixity_check)
      described_class.fixity_check_everything
    end
  end
end
