require 'spec_helper'

describe Sufia::SelectTypeListPresenter do
  let(:instance) { described_class.new(user) }
  let(:user) { create(:user) }

  describe "#many?" do
    subject { instance.many? }
    it { is_expected.to be false }

    context "if user is nil" do
      it { is_expected.to be false }
    end

    context "if authorized_models returns more than one" do
      before do
        allow(instance).to receive(:authorized_models).and_return([double, double])
      end
      it { is_expected.to be true }
    end
  end
end
