# frozen_string_literal: true

RSpec.describe Hyrax::EmbargoHelper do
  let(:resource) { build(:monograph) }

  describe 'embargo_enforced?' do
    # Including this stub to preserve the spec structure before the #4845 change
    before { allow(resource).to receive(:persisted?).and_return(true) }

    context 'with a non-persisted object' do
      let(:resource) { build(:hyrax_work, :under_embargo) }

      before { Hyrax::EmbargoManager.apply_embargo_for!(resource: resource) }

      it 'returns false' do
        # NOTE: This spec echoes "embargo_enforced? with a Hyrax::Work when an embargo is enforced on the resource"
        allow(resource).to receive(:persisted?).and_return false
        expect(embargo_enforced?(resource)).to be false
      end
    end

    context 'with a Hyrax::Work' do
      let(:resource) { build(:hyrax_work) }

      it 'returns false' do
        expect(embargo_enforced?(resource)).to be false
      end

      context 'when an embargo is enforced on the resource' do
        let(:resource) { build(:hyrax_work, :under_embargo) }

        before { Hyrax::EmbargoManager.apply_embargo_for!(resource: resource) }

        it 'returns true' do
          expect(embargo_enforced?(resource)).to be true
        end

        context 'and the embargo is expired' do
          before do
            resource.embargo.embargo_release_date = Time.zone.today - 1
          end

          it 'returns true' do
            expect(embargo_enforced?(resource)).to be true
          end
        end
      end
    end

    context 'with a change set' do
      let(:resource) { Hyrax::ChangeSet.for(build(:hyrax_work)) }

      it 'returns false' do
        expect(embargo_enforced?(resource)).to be false
      end

      context 'when an embargo is enforced on the resource' do
        let(:resource) do
          Hyrax::ChangeSet.for(build(:hyrax_work, :under_embargo))
        end

        before do
          Hyrax::EmbargoManager.apply_embargo_for!(resource: resource.model)
        end

        it 'returns true' do
          expect(embargo_enforced?(resource)).to be true
        end

        context 'and the embargo is expired' do
          before do
            resource.model.embargo.embargo_release_date = Time.zone.today - 1
          end

          it 'returns true' do
            expect(embargo_enforced?(resource)).to be true
          end
        end
      end
    end

    context 'with an ActiveFedora resource', :active_fedora do
      let(:resource) { build(:work) }

      it 'returns false' do
        expect(embargo_enforced?(resource)).to be false
      end

      context 'when the resource is under embargo' do
        let(:resource) { build(:embargoed_work) }

        it 'returns true' do
          expect(embargo_enforced?(resource)).to be true
        end

        it 'and the embargo is expired returns true' do
          resource.embargo.embargo_release_date = Time.zone.today - 1

          expect(embargo_enforced?(resource)).to be true
        end

        it 'and the embargo is deactivated returns false' do
          resource.embargo.embargo_release_date = Time.zone.today - 1
          resource.embargo.deactivate!

          expect(embargo_enforced?(resource)).to be false
        end
      end
    end

    context 'with a HydraEditor::Form (ActiveFedora)', :active_fedora do
      let(:resource) { Hyrax::GenericWorkForm.new(model, ability, form_controller) }
      let(:model) { build(:work) }
      let(:ability) { :FAKE_ABILITY }
      let(:form_controller) { :FAKE_CONTROLLER }

      it 'returns false' do
        expect(embargo_enforced?(resource)).to be false
      end

      context 'when the wrapped work is under embargo' do
        let(:model) { build(:embargoed_work) }

        it 'returns true' do
          # This allow call is a tweak to preserve spec for pre #4845 patch
          allow(model).to receive(:persisted?).and_return(true)

          expect(embargo_enforced?(resource)).to be true
        end
      end
    end

    context 'with a Hyrax::Forms::FailedSubmissionFormWrapper (ActiveFedora)', :active_fedora do
      let(:resource) { Hyrax::Forms::FailedSubmissionFormWrapper.new(form: form, input_params: {}, permitted_params: {}) }
      let(:form) { Hyrax::GenericWorkForm.new(model, ability, form_controller) }
      let(:model) { build(:work) }
      let(:ability) { :FAKE_ABILITY }
      let(:form_controller) { :FAKE_CONTROLLER }

      it 'returns false' do
        expect(embargo_enforced?(resource)).to be false
      end

      context 'when the wrapped work is under embargo' do
        let(:model) { build(:embargoed_work) }

        it 'returns true' do
          # This allow call is a tweak to preserve spec for pre #4845 patch
          allow(model).to receive(:persisted?).and_return(true)
          expect(embargo_enforced?(resource)).to be true
        end
      end
    end
  end

  describe '#embargo_history' do
    context 'with an ActiveFedora resource', :active_fedora do
      let(:resource) { FactoryBot.build(:work) }

      it 'is empty' do
        expect(embargo_history(resource)).to be_empty
      end

      context 'when the resource is under embargo' do
        let(:resource) { FactoryBot.build(:embargoed_work) }

        before do
          resource.embargo.embargo_history << "updated the lease"
        end

        it 'has a history' do
          expect(embargo_history(resource)).to contain_exactly("updated the lease")
        end
      end
    end

    context 'with a Hyrax::Work' do
      let(:resource) { FactoryBot.build(:hyrax_work) }

      it 'is empty' do
        expect(embargo_history(resource)).to be_empty
      end

      context 'when the resource is under embargo' do
        let(:resource) { FactoryBot.build(:hyrax_work, :under_embargo) }

        before do
          resource.embargo.embargo_history = ['Embargo in place!', 'Embargo expired!']
        end

        it 'contains the lease history' do
          expect(embargo_history(resource))
            .to contain_exactly 'Embargo in place!', 'Embargo expired!'
        end
      end
    end
  end
end
