# frozen_string_literal: true
RSpec.describe Hyrax::Strategies::YamlStrategy do
  subject { described_class.new(config: tmpfile) }

  context "when given a YAML file" do
    let(:content) { { "assign_admin_set" => { "enabled" => false } }.to_yaml }
    let(:tmpfile) { Tempfile.new }

    before do
      tmpfile.write(content)
      tmpfile.rewind
    end

    after do
      tmpfile.close
      tmpfile.unlink
    end

    it "tests for features based on an enabled key" do
      expect(subject.enabled?(:assign_admin_set)).to eq false
    end
    it "returns nil for unknown features" do
      expect(subject.enabled?(:unknown_Feature)).to be_nil
    end
  end

  context "when given a non-existent file" do
    let(:tmpfile) { "/tmp/non-existent-file" }

    it "returns nil for everything" do
      expect(subject.enabled?(:assign_admin_set)).to be_nil
    end
  end
end
