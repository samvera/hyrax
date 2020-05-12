# frozen_string_literal: true

RSpec.describe Hyrax::EmbargoHelper do
  let(:resource) { build(:monograph) }

  describe 'embargo_enforced?' do
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

    context 'with an ActiveFedora resource' do
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

    context 'with a HydraEditor::Form' do
      let(:resource) { Hyrax::GenericWorkForm.new(build(:work), ability, form_controller) }
      let(:ability) { :FAKE_ABILITY }
      let(:form_controller) { :FAKE_CONTROLLER }

      it 'returns false' do
        expect(embargo_enforced?(resource)).to be false
      end

      context 'when the wrapped work is under embargo' do
        let(:resource) { Hyrax::GenericWorkForm.new(build(:embargoed_work), ability, form_controller) }

        it 'returns true' do
          expect(embargo_enforced?(resource)).to be true
        end
      end
    end
  end
end
