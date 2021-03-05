# frozen_string_literal: true

RSpec.describe Hyrax::GoogleScholarPresenter do
  subject(:presenter) { described_class.new(work) }
  let(:work) { FactoryBot.build(:monograph) }

  describe '#scholarly?' do
    it { is_expected.to be_scholarly }

    context 'when the decorated object says it is not scholarly' do
      let(:work) { double(:scholarly? => false) }

      it { is_expected.not_to be_scholarly }
    end
  end
end
