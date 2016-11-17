require 'spec_helper'
describe CurationConcerns::Actors::InterpretVisibilityActor do
  let(:user) { create(:user) }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { {} }
  subject do
    CurationConcerns::Actors::ActorStack.new(curation_concern,
                                             user,
                                             [described_class,
                                              CurationConcerns::Actors::GenericWorkActor])
  end
  let(:date) { Date.today + 2 }

  describe 'the next actor' do
    let(:root_actor) { double }
    before do
      allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(root_actor)
      allow(curation_concern).to receive(:save).and_return(true)
    end

    context 'when visibility is  set to open' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          visibility_during_embargo: 'restricted',
          visibility_after_embargo: 'open',
          embargo_release_date: date.to_s }
      end

      it 'does not receive the embargo attributes' do
        expect(root_actor).to receive(:create).with(visibility: 'open')
        subject.create(attributes)
      end
    end

    context 'when visibility is set to embargo' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
          visibility_during_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
          visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          embargo_release_date: date.to_s }
      end

      it 'does not receive the visibility attribute' do
        expect(root_actor).to receive(:create).with(hash_excluding(:visibility))
        subject.create(attributes)
      end

      context 'when embargo_release_date is not set' do
        let(:attributes) { { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO } }
        it 'does not clear the visibility attributes' do
          expect(subject.create(attributes)).to be false
          expect(attributes).to eq(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO)
        end
      end
    end

    context 'when visibility is set to lease' do
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
          visibility_during_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
          visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
          lease_expiration_date: date.to_s }
      end

      it 'removes lease attributes' do
        expect(root_actor).to receive(:create).with(hash_excluding(:visibility))
        subject.create(attributes)
      end

      context 'when lease_expiration_date is not set' do
        let(:attributes) { { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE } }
        it 'sets error on curation_concern and return false' do
          expect(subject.create(attributes)).to be false
          expect(attributes).to eq(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE)
        end
      end
    end
  end

  describe 'create' do
    context 'with embargo' do
      let(:attributes) do
        { title: ['New embargo'], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
          visibility_during_embargo: 'authenticated', embargo_release_date: date.to_s,
          visibility_after_embargo: 'open', visibility_during_lease: 'open',
          lease_expiration_date: '2014-06-12', visibility_after_lease: 'restricted',
          rights: ['http://creativecommons.org/licenses/by/3.0/us/'] }
      end

      context 'with a valid embargo date' do
        let(:date) { Date.today + 2 }
        it 'interprets and apply embargo and lease visibility settings' do
          subject.create(attributes)
          expect(curation_concern.visibility_during_embargo).to eq 'authenticated'
          expect(curation_concern.visibility_after_embargo).to eq 'open'
          expect(curation_concern.visibility).to eq 'authenticated'
        end
      end

      context 'when embargo_release_date is in the past' do
        let(:date) { Date.today - 2 }
        it 'sets error on curation_concern and return false' do
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:embargo_release_date].first).to eq 'Must be a future date'
        end
      end
    end

    context 'with lease' do
      let(:attributes) do
        { title: ['New embargo'], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
          visibility_during_embargo: 'authenticated', embargo_release_date: '2099-05-12',
          visibility_after_embargo: 'open', visibility_during_lease: 'open',
          lease_expiration_date: date.to_s, visibility_after_lease: 'restricted',
          rights: ['http://creativecommons.org/licenses/by/3.0/us/'] }
      end

      context 'with a valid lease date' do
        let(:date) { Date.today + 2 }
        it 'interprets and apply embargo and lease visibility settings' do
          subject.create(attributes)
          expect(curation_concern.embargo_release_date).to be_nil
          expect(curation_concern.visibility_during_lease).to eq 'open'
          expect(curation_concern.visibility_after_lease).to eq 'restricted'
          expect(curation_concern.visibility).to eq 'open'
        end
      end

      context 'when lease_expiration_date is in the past' do
        let(:date) { Date.today - 2 }
        it 'sets error on curation_concern and return false' do
          expect(subject.create(attributes)).to be false
          expect(subject.curation_concern.errors[:lease_expiration_date].first).to eq 'Must be a future date'
        end
      end
    end
  end
end
