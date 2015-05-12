require 'spec_helper'

describe Sufia::VersioningService do
  describe "#latest_version_of" do
    let(:file) do
      GenericFile.new do |f|
        f.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
        f.apply_depositor_metadata('mjg36')
      end
    end

    before do
      file.content.versionable = true
      file.save!
      file.content.create_version
    end

    subject { described_class.latest_version_of(file.content).label }

    context "with one version" do
      it { is_expected.to eq "version1" }
    end

    context "with two versions" do
      before do
        file.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
        file.save!
        file.content.create_version
      end
      it { is_expected.to eq "version2" }
    end
  end

end
