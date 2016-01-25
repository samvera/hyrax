require 'spec_helper'
require 'redlock'

describe CurationConcerns::GenericWorkActor do
  include ActionDispatch::TestProcess

  let(:user) { FactoryGirl.create(:user) }
  let(:file) { curation_concerns_fixture_file_upload('files/image.png', 'image/png') }

  let(:redlock_client_stub) { # stub out redis connection
    client = double('redlock client')
    allow(client).to receive(:lock).and_yield(true)
    allow(Redlock::Client).to receive(:new).and_return(client)
    client
  }

  subject do
    CurationConcerns::CurationConcern.actor(curation_concern, user, attributes)
  end

  describe '#create' do
    let(:curation_concern) { GenericWork.new }
    let(:xmas) { DateTime.parse('2014-12-25 11:30') }

    context 'failure' do
      let(:attributes) { {} }

      it 'returns false' do
        expect_any_instance_of(described_class).to receive(:save).and_return(false)
        allow(subject).to receive(:attach_files).and_return(true)
        expect(subject.create).to be false
      end
    end

    context 'valid attributes' do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }

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
            subject.create
            expect(curation_concern).to be_persisted
            expect(curation_concern.visibility_during_embargo).to eq 'authenticated'
            expect(curation_concern.visibility_after_embargo).to eq 'open'
            expect(curation_concern.visibility).to eq 'authenticated'
          end
          context "with attached files" do
            let(:attributes) do
              { title: ['New embargo'], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
                visibility_during_embargo: 'authenticated', embargo_release_date: date.to_s,
                visibility_after_embargo: 'open', visibility_during_lease: 'open',
                lease_expiration_date: '2014-06-12', visibility_after_lease: 'restricted',
                files: [
                  file
                ],
                rights: ['http://creativecommons.org/licenses/by/3.0/us/'] }
            end

            before { redlock_client_stub }

            it "applies it to attached files" do
              allow(CharacterizeJob).to receive(:perform_later).and_return(true)
              subject.create
              file = curation_concern.file_sets.first
              expect(file).to be_persisted
              expect(file.visibility_during_embargo).to eq 'authenticated'
              expect(file.visibility_after_embargo).to eq 'open'
              expect(file.visibility).to eq 'authenticated'
            end
          end
        end

        context 'when embargo_release_date is in the past' do
          let(:date) { Date.today - 2 }
          it 'sets error on curation_concern and return false' do
            expect(subject.create).to be false
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
            subject.create
            expect(curation_concern).to be_persisted
            expect(curation_concern.embargo_release_date).to be_nil
            expect(curation_concern.visibility_during_lease).to eq 'open'
            expect(curation_concern.visibility_after_lease).to eq 'restricted'
            expect(curation_concern.visibility).to eq 'open'
          end
        end

        context 'when lease_expiration_date is in the past' do
          let(:date) { Date.today - 2 }
          it 'sets error on curation_concern and return false' do
            expect(subject.create).to be false
            expect(subject.curation_concern.errors[:lease_expiration_date].first).to eq 'Must be a future date'
          end
        end
      end

      context 'with a file' do
        let(:attributes) do
          FactoryGirl.attributes_for(:generic_work, visibility: visibility).tap do |a|
            a[:files] = file
          end
        end

        context 'authenticated visibility' do
          before do
            allow(CurationConcerns::TimeService).to receive(:time_in_utc) { xmas }
            redlock_client_stub
          end

          it 'stamps each file with the access rights' do
            expect(CharacterizeJob).to receive(:perform_later)
            expect(subject.create).to be true
            expect(curation_concern).to be_persisted
            expect(curation_concern.date_uploaded).to eq xmas
            expect(curation_concern.date_modified).to eq xmas
            expect(curation_concern.depositor).to eq user.user_key
            expect(curation_concern.representative).to_not be_nil
            expect(curation_concern.file_sets.size).to eq 1
            # Sanity test to make sure the file we uploaded is stored and has same permission as parent.
            file_set = curation_concern.file_sets.first
            file.rewind
            expect(file_set.reload.original_file.content).to eq file.read

            expect(curation_concern).to be_authenticated_only_access
            expect(file_set).to be_authenticated_only_access
          end
        end
      end

      context 'with multiple files file' do
        let(:attributes) do
          FactoryGirl.attributes_for(:generic_work, visibility: visibility).tap do|a|
            a[:files] = [file, file]
          end
        end

        context 'authenticated visibility' do
          before do
            allow(CurationConcerns::TimeService).to receive(:time_in_utc) { xmas }
            redlock_client_stub
          end

          it 'stamps each file with the access rights' do
            expect(CharacterizeJob).to receive(:perform_later).twice

            expect(subject.create).to be true
            expect(curation_concern).to be_persisted
            expect(curation_concern.date_uploaded).to eq xmas
            expect(curation_concern.date_modified).to eq xmas
            expect(curation_concern.depositor).to eq user.user_key

            expect(curation_concern.file_sets.size).to eq 2
            # Sanity test to make sure the file we uploaded is stored and has same permission as parent.

            expect(curation_concern).to be_authenticated_only_access
          end
        end
      end

      context 'with a present and a blank title' do
        let(:attributes) do
          FactoryGirl.attributes_for(:generic_work, title: ['this is present', ''])
        end

        it 'stamps each link with the access rights' do
          expect(subject.create).to be true
          expect(curation_concern).to be_persisted
          expect(curation_concern.title).to eq ['this is present']
        end
      end
    end
  end

  describe '#update' do
    let(:curation_concern) { FactoryGirl.create(:generic_work, user: user) }

    context 'failure' do
      let(:attributes) { {} }

      it 'returns false' do
        expect_any_instance_of(described_class).to receive(:save).and_return(false)
        expect(subject.update).to be false
      end
    end

    context 'valid attributes' do
      let(:attributes) { {} }
      it 'interprets and apply embargo and lease visibility settings' do
        expect(subject).to receive(:interpret_lease_visibility).and_return(true)
        expect(subject).to receive(:interpret_embargo_visibility).and_return(true)
        subject.update
      end
    end

    context 'adding to collections' do
      let!(:collection1) { FactoryGirl.create(:collection, user: user) }
      let!(:collection2) { FactoryGirl.create(:collection, user: user) }
      let(:attributes) do
        FactoryGirl.attributes_for(:generic_work, collection_ids: [collection2.id])
      end
      before do
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
        collection1.members << curation_concern
        collection1.save!
      end

      it 'remove from the old collection and adds to the new collection' do
        curation_concern.reload
        expect(curation_concern.in_collections).to eq [collection1]
        # before running actor.update, the work is in collection1

        expect(subject.update).to be true

        curation_concern.reload
        expect(curation_concern.identifier).to be_blank
        expect(curation_concern).to be_persisted
        # after running actor.update, the work is in collection2 and no longer in collection1
        expect(curation_concern.in_collections).to eq [collection2]
      end
    end

    context 'with multiple file sets' do
      let(:file_set1) { create(:file_set) }
      let(:file_set2) { create(:file_set) }
      let(:curation_concern) { FactoryGirl.create(:generic_work, user: user, members: [file_set1, file_set2]) }
      let(:attributes) do
        FactoryGirl.attributes_for(:generic_work, members: [file_set2, file_set1])
      end
      xit 'updates the order of file sets' do
        expect(curation_concern.ordered_members).to eq [file_set1, file_set2]
        expect(subject.update).to be true
        curation_concern.reload
        expect(curation_concern.ordered_members).to eq [file_set2, file_set1]
      end
    end
  end
end
