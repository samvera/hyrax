# frozen_string_literal: true

RSpec.describe Hyrax::LeaseHelper do
  let(:resource) { build(:monograph) }

  describe 'lease_enforced?' do
    context 'with an ActiveFedora resource' do
      let(:resource) { build(:work) }

      it 'returns false' do
        expect(lease_enforced?(resource)).to be false
      end

      context 'when the resource is under lease' do
        let(:resource) { build(:leased_work) }

        it 'returns true' do
          expect(lease_enforced?(resource)).to be true
        end

        it 'and the lease is expired returns true' do
          resource.lease.lease_expiration_date = Time.zone.today - 1

          expect(lease_enforced?(resource)).to be true
        end

        it 'and the lease is deactivated returns false' do
          resource.lease.lease_expiration_date = Time.zone.today - 1
          resource.lease.deactivate!

          expect(lease_enforced?(resource)).to be false
        end
      end
    end
  end
end
