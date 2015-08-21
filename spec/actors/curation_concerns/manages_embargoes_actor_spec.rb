require 'spec_helper'
describe CurationConcerns::ManagesEmbargoesActor do
  let(:model) do
    Class.new(CurationConcerns::BaseActor) do
      include CurationConcerns::ManagesEmbargoesActor
    end
  end

  let(:user) { User.new }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { {} }
  subject do
    model.new(curation_concern, user, attributes)
  end
  let(:date) { Date.today + 2 }

  context '#interpret_visibility' do
    it 'interprets lease and embargo visibility' do
      expect(subject).to receive(:interpret_lease_visibility).and_return(true)
      expect(subject).to receive(:interpret_embargo_visibility).and_return(true)
      expect(subject.interpret_visibility).to be true
    end
    it 'collects failures from interpreting lease & embargo visibility' do
      expect(subject).to receive(:interpret_embargo_visibility).and_return(true)
      expect(subject).to receive(:interpret_lease_visibility).and_return(false)
      expect(subject.interpret_visibility).to be false
    end
  end

  context '#interpret_embargo_visibility' do
    context 'when visibility is not set to embargo' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          visibility_during_embargo: 'restricted', visibility_after_embargo: 'open' }
      end
      it 'removes the embargo attributes and returns true' do
        expect(subject.interpret_embargo_visibility).to be true
        expect(subject.attributes.keys).to eq ['visibility']
      end
    end

    context 'when visibility is set to embargo' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
          visibility_during_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
          visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          embargo_release_date: date.to_s }
      end

      it 'applies the embargo remove embargo attributes except for embargo_release_date and return true' do
        expect(subject.curation_concern).to receive(:apply_embargo).with(date.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        expect(subject.interpret_embargo_visibility).to be true
        expect(subject.attributes.keys).to eq ['embargo_release_date']
      end

      context 'when embargo_release_date is not set' do
        let(:attributes) { { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO } }
        it 'sets error on curation_concern and return false' do
          expect(subject.interpret_embargo_visibility).to be false
          expect(subject.curation_concern.errors[:visibility].first).to eq 'When setting visibility to "embargo" you must also specify embargo release date.'
        end
      end
    end
  end

  context '#interpret_lease_visibility' do
    context 'when visibility is not set to lease' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          visibility_during_lease: 'open', visibility_after_lease: 'restricted' }
      end
      it 'removes the lease attributes and returns true' do
        expect(subject.interpret_lease_visibility).to be true
        expect(subject.attributes.keys).to eq ['visibility']
      end
    end

    context 'when visibility is set to lease' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
          visibility_during_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
          visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          lease_expiration_date: date.to_s }
      end

      it 'applies the lease, remove lease attributes except for lease_expiration_date and return true' do
        expect(subject.curation_concern).to receive(:apply_lease).with(date.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        expect(subject.interpret_lease_visibility).to be true
        expect(subject.attributes.keys).to eq ['lease_expiration_date']
      end

      context 'when lease_expiration_date is not set' do
        let(:attributes) { { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE } }
        it 'sets error on curation_concern and return false' do
          expect(subject.interpret_lease_visibility).to be false
          expect(subject.curation_concern.errors[:visibility].first).to eq 'When setting visibility to "lease" you must also specify lease expiration date.'
        end
      end
    end
  end
end
