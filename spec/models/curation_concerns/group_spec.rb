require 'spec_helper'

RSpec.describe CurationConcerns::Group do
  let(:instance) { described_class.new('librarians') }
  let(:other_instance) { described_class.new('librarians') }

  describe "#to_sipity_agent" do
    it "is a Sipity::Agent" do
      expect(instance.to_sipity_agent).to be_kind_of Sipity::Agent
    end
    it "only creates one" do
      expect(instance.to_sipity_agent).to eq other_instance.to_sipity_agent
    end
  end
end
