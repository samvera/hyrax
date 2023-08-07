# frozen_string_literal: true

RSpec.describe Hyrax::LeaseManager do
  subject(:manager) { described_class.new(resource: resource) }
  let(:resource)    { Hyrax::Resource.new }

  shared_context 'when under lease' do
    let(:resource) { FactoryBot.build(:hyrax_resource, :under_lease) }
  end

  shared_context 'with expired lease' do
    let(:resource) { FactoryBot.build(:hyrax_resource, lease: lease) }
    let(:lease)    { FactoryBot.create(:hyrax_lease, :expired) }
  end

  describe '#apply' do
    context 'with no lease' do
      it 'is a no-op' do
        expect { manager.apply }
          .not_to change { resource.visibility }
      end
    end

    context 'with expired lease' do
      include_context 'with expired lease'

      it 'is a no-op' do
        expect { manager.apply }
          .not_to change { resource.visibility }
      end
    end

    context 'when under lease' do
      include_context 'when under lease'

      before { resource.visibility = 'restricted' }

      it 'applies the active lease visibility' do
        expect { manager.apply }
          .to change { resource.visibility }
          .from('restricted')
          .to 'open'
      end
    end
  end

  describe '#enforced' do
    it { is_expected.not_to be_enforced }

    context 'when under lease' do
      include_context 'when under lease'

      it { is_expected.not_to be_enforced }

      context 'and it is applied' do
        before { manager.apply! }

        it { is_expected.to be_enforced }
      end
    end

    context 'with expired lease' do
      include_context 'with expired lease'

      it { is_expected.not_to be_enforced }
    end

    context 'with an lease that is in force, but expired' do
      include_context 'with expired lease'

      before { resource.visibility = lease.visibility_during_lease }

      it { is_expected.to be_enforced }
    end
  end

  describe '#lease' do
    it 'gives an inactive lease' do
      expect(manager.lease).not_to be_active
    end

    context 'when under lease' do
      include_context 'when under lease'

      it 'gives an active lease' do
        expect(manager.lease).to be_active
      end

      it 'has lease attributes' do
        expect(manager.lease)
          .to have_attributes visibility_after_lease: 'authenticated',
                              visibility_during_lease: 'open',
                              lease_expiration_date: an_instance_of(DateTime),
                              lease_history: be_empty
      end
    end
  end

  describe '#release' do
    context 'with no lease' do
      it 'is a no-op' do
        expect { manager.release }
          .not_to change { resource.visibility }
      end
    end

    context 'with expired lease' do
      include_context 'with expired lease'

      it 'ensures the post-lease visibility is set' do
        manager.release
        expect(resource.visibility).to eq lease.visibility_after_lease
      end

      context 'and lease was applied' do
        before { resource.visibility = lease.visibility_during_lease }

        it 'ensures the post-lease visibility is set' do
          expect { manager.release }
            .to change { resource.visibility }
            .from(lease.visibility_during_lease)
            .to lease.visibility_after_lease
        end
      end
    end

    context 'when under lease' do
      include_context 'when under lease'

      it 'is a no-op' do
        expect { manager.release }
          .not_to change { resource.visibility }
      end
    end
  end

  describe '#under_lease?' do
    it { is_expected.not_to be_under_lease }

    context 'when under lease' do
      include_context 'when under lease'

      it { is_expected.to be_under_lease }
    end

    context 'with expired lease' do
      include_context 'with expired lease'

      it { is_expected.not_to be_under_lease }
    end
  end
end
