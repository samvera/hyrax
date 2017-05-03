# frozen_string_literal: true

RSpec.describe Hyrax::RepositoryFixityCheckService do
  let(:user) { FactoryGirl.create(:user) }
  let!(:file) do
    FileSet.create! do |file|
      file.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
      file.apply_depositor_metadata(user)
    end
  end

  describe "#fixity_check_everything" do
    it "fixity checks everything" do
      # make sure the fixity check gets called
      expect_any_instance_of(Hyrax::FileSetFixityCheckService).to receive(:fixity_check)
      described_class.fixity_check_everything
    end
  end
end
