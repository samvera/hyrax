# frozen_string_literal: true
RSpec.describe Hyrax::Noid do
  let(:class_with_noids) do
    Class.new do
      include Hyrax::Noid
      attr_reader :id
      def initialize(id:)
        @id = id
      end
    end
  end
  let(:object) { class_with_noids.new(id: 1234) }

  describe 'when noids are not enabled' do
    before { expect(Hyrax.config).to receive(:enable_noids?).and_return(false) }
    subject { object.assign_id }

    it { is_expected.to be_nil }
    it 'will not update the id (as the name might imply)' do
      expect { object.assign_id }.not_to change { object.id }
    end
  end

  describe 'when noids is enabled' do
    let(:service) { double(mint: 5678) }

    before do
      expect(Hyrax.config).to receive(:enable_noids?).and_return(true)
      expect(object).to receive(:service).and_return(service)
    end
    subject { object.assign_id }

    it { is_expected.to eq(service.mint) }
    it 'will not update the id (as the name might imply)' do
      expect { object.assign_id }.not_to change { object.id }
    end
  end
end
