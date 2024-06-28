# frozen_string_literal: true
RSpec.describe Hyrax::QuickClassificationQuery do
  let(:user) { create(:user) }

  context "with no options" do
    let(:query) { described_class.new(user) }

    describe "#all?" do
      subject { query.all? }

      it { is_expected.to be true }
    end

    describe '#each' do
      let(:thing) { double }

      it "calls the block once for every model" do
        expect(Hyrax.config.curation_concerns.size).to be > 0
        Hyrax.config.curation_concerns.each do |cc|
          expect(thing).to receive(:test).with(cc)
        end

        query.each { |f| thing.test(f) }
      end
    end
  end

  context "with models" do
    let(:query) { described_class.new(user, models: ['dataset']) }

    describe "#all?" do
      subject { query.all? }

      it { is_expected.to be false }
    end
  end
end
