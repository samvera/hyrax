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

  describe '#ensure_valid_state' do
    let(:work) { FactoryBot.build(:work) }

    context 'in an already valid minter state' do
      it 'returns true' do
        expect(object.ensure_valid_minter_state).to eq true
      end
    end

    context 'with an ldp conflict state' do
      before(:context) do
        Hyrax.config.enable_noids = true
        # we need to mint once to set the `rand` database column and
        # make minter behavior predictable
        ::Noid::Rails.config.minter_class.new.mint
      end
      after(:context) { Hyrax.config.enable_noids = false }

      before do
        ActiveRecord::Base.transaction do
          FactoryBot.create_list(:work, 3)

          raise ActiveRecord::Rollback
        end
      end

      it 'reinstates a valid minter state' do

        aggregate_failures 'minter state transitions' do
          expect { FactoryBot.create(:work) }.to raise_error Ldp::Conflict
          object.ensure_valid_minter_state
          expect(FactoryBot.create(:work)).to have_attributes(id: an_instance_of(String))
        end
      end
    end
  end
end
