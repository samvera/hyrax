require 'spec_helper'

RSpec.describe CurationConcerns::Forms::FileManagerForm do
  let(:work) { create(:work) }
  let(:ability) { instance_double Ability }
  let(:form) { described_class.new(work, ability) }

  describe "#member_presenters" do
    subject { form.member_presenters }
    let(:factory) { instance_double(CurationConcerns::MemberPresenterFactory, member_presenters: result) }
    let(:result) { double }
    before do
      allow(CurationConcerns::MemberPresenterFactory).to receive(:new).with(work, ability).and_return(factory)
    end
    it "is delegated to the MemberPresenterFactory" do
      expect(subject).to eq result
    end
  end
end
