# frozen_string_literal: true

RSpec.describe Hyrax::LeaseHelper do
  let(:resource) { build(:monograph) }

  describe 'lease_enforced?' do
    context 'with a Hyrax::Work' do
      let(:resource) { build(:hyrax_work) }

      it 'returns false' do
        expect(lease_enforced?(resource)).to be false
      end

      context 'when a lease is enforced on the resource' do
        let(:resource) { build(:hyrax_work, :under_lease) }

        before { Hyrax::LeaseManager.apply_lease_for!(resource: resource) }

        it 'returns true' do
          expect(lease_enforced?(resource)).to be true
        end

        context 'and the lease is expired' do
          before do
            resource.lease.lease_expiration_date = Time.zone.today - 1
          end

          it 'returns true' do
            expect(lease_enforced?(resource)).to be true
          end
        end
      end
    end

    context 'with a change set' do
      let(:resource) { Hyrax::ChangeSet.for(build(:hyrax_work)) }

      it 'returns false' do
        expect(lease_enforced?(resource)).to be false
      end

      context 'when a lease is enforced on the resource' do
        let(:resource) { Hyrax::ChangeSet.for(build(:hyrax_work, :under_lease)) }

        before do
          Hyrax::LeaseManager.apply_lease_for!(resource: resource.model)
        end

        it 'returns true' do
          expect(lease_enforced?(resource)).to be true
        end

        context 'and the lease is expired' do
          before do
            resource.model.lease.lease_expiration_date = Time.zone.today - 1
          end

          it 'returns true' do
            expect(lease_enforced?(resource)).to be true
          end
        end
      end
    end

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

    context 'with a HydraEditor::Form' do
      let(:resource) { Hyrax::GenericWorkForm.new(build(:work), ability, form_controller) }
      let(:ability) { :FAKE_ABILITY }
      let(:form_controller) { :FAKE_CONTROLLER }

      it 'returns false' do
        expect(lease_enforced?(resource)).to be false
      end

      context 'when the wrapped work is under lease' do
        let(:resource) { Hyrax::GenericWorkForm.new(build(:leased_work), ability, form_controller) }

        it 'returns true' do
          expect(lease_enforced?(resource)).to be true
        end
      end
    end

    context 'with a Hyrax::Forms::FailedSubmissionFormWrapper' do
      let(:resource) { Hyrax::Forms::FailedSubmissionFormWrapper.new(form: form, input_params: {}, permitted_params: {}) }
      let(:form) { Hyrax::GenericWorkForm.new(build(:work), ability, form_controller) }
      let(:ability) { :FAKE_ABILITY }
      let(:form_controller) { :FAKE_CONTROLLER }

      it 'returns false' do
        expect(lease_enforced?(resource)).to be false
      end

      context 'when the wrapped work is under embargo' do
        let(:form) { Hyrax::GenericWorkForm.new(build(:leased_work), ability, form_controller) }

        it 'returns true' do
          expect(lease_enforced?(resource)).to be true
        end
      end
    end
  end
end
