# frozen_string_literal: true
RSpec.describe Hyrax::Strategies::YamlStrategy do
  subject { described_class.new(config: "test_file") }

  context "when given a YAML file" do
    let(:content) do
      {
        "assign_admin_set" => {
          "enabled" => false
        }
      }
    end

    before do
      allow(YAML).to receive(:load_file).with("test_file").and_return(content)
      allow(File).to receive(:exist?).with("test_file").and_return(true)
    end
    it "tests for features based on an enabled key" do
      expect(subject.enabled?(:assign_admin_set)).to eq false
    end
    it "returns nil for unknown features" do
      expect(subject.enabled?(:unknown_Feature)).to be_nil
    end
  end

  context "when given a non-existent file" do
    it "returns nil for everything" do
      expect(subject.enabled?(:assign_admin_set)).to be_nil
    end
  end
end
