require 'spec_helper'

RSpec.describe Hyrax::Forms::FileManagerForm do
  subject { described_class.new(resource, nil) }
  let(:resource) { GenericWork.new(id: "test") }

  describe "#member_presenters" do
    it "returns an empty array by default" do
      expect(subject.member_presenters).to eq []
    end
  end
end
