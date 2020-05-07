# frozen_string_literal: true

RSpec.describe Hyrax::EmbargoHelper do
  let(:resource) { build(:monograph) }

  describe 'embargo_enforced?' do
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
  end
end
