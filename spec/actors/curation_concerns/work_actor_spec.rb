require 'spec_helper'
require 'redlock'

describe CurationConcerns::Actors::GenericWorkActor do
  include ActionDispatch::TestProcess

  let(:user) { create(:user) }
  let(:file) { curation_concerns_fixture_file_upload('files/image.png', 'image/png') }

  # stub out redis connection
  let(:redlock_client_stub) do
    client = double('redlock client')
    allow(client).to receive(:lock).and_yield(true)
    allow(Redlock::Client).to receive(:new).and_return(client)
    client
  end

  subject do
    CurationConcerns::CurationConcern.actor(curation_concern, user)
  end

  describe '#create' do
    let(:curation_concern) { GenericWork.new }
    let(:xmas) { DateTime.parse('2014-12-25 11:30') }

    context 'failure' do
      let(:attributes) { {} }

      it 'returns false' do
        expect_any_instance_of(described_class).to receive(:save).and_return(false)
        allow(subject).to receive(:attach_files).and_return(true)
        expect(subject.create(attributes)).to be false
      end
    end

    context 'success' do
      before do
        redlock_client_stub
        create(:workflow_action)
      end

      it "invokes the after_create_concern callback" do
        allow(CharacterizeJob).to receive(:perform_later).and_return(true)
        expect(CurationConcerns.config.callback).to receive(:run)
          .with(:after_create_concern, curation_concern, user)
        subject.create(title: ['Foo Bar'])
      end
    end

    context 'valid attributes' do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      before do
        redlock_client_stub
        create(:workflow_action)
      end

      context 'with embargo' do
        context "with attached files" do
          let(:date) { Date.today + 2 }
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

          it "applies embargo to attached files" do
            allow(CharacterizeJob).to receive(:perform_later).and_return(true)
            subject.create(attributes)
            file = curation_concern.file_sets.first
            expect(file).to be_persisted
            expect(file.visibility_during_embargo).to eq 'authenticated'
            expect(file.visibility_after_embargo).to eq 'open'
            expect(file.visibility).to eq 'authenticated'
          end
        end
      end

      context 'with in_work_ids' do
        let(:parent) { FactoryGirl.create(:generic_work) }
        let(:attributes) do
          FactoryGirl.attributes_for(:generic_work, visibility: visibility).merge(
            in_works_ids: [parent.id]
          )
        end
        it "attaches the parent" do
          expect(subject.create(attributes)).to be true
          expect(curation_concern.in_works).to eq [parent]
        end
      end

      context 'with a file' do
        let(:attributes) do
          FactoryGirl.attributes_for(:generic_work, visibility: visibility).tap do |a|
            a[:files] = file
          end
        end

        context 'authenticated visibility' do
          let(:file_actor) { double }
          before do
            allow(CurationConcerns::TimeService).to receive(:time_in_utc) { xmas }
            allow(CurationConcerns::Actors::FileActor).to receive(:new).and_return(file_actor)
          end

          it 'stamps each file with the access rights' do
            expect(file_actor).to receive(:ingest_file).and_return(true)
            expect(subject.create(attributes)).to be true
            expect(curation_concern).to be_persisted
            expect(curation_concern.date_uploaded).to eq xmas
            expect(curation_concern.date_modified).to eq xmas
            expect(curation_concern.depositor).to eq user.user_key
            expect(curation_concern.representative).to_not be_nil
            expect(curation_concern.file_sets.size).to eq 1
            expect(curation_concern).to be_authenticated_only_access
            # Sanity test to make sure the file_set has same permission as parent.
            file_set = curation_concern.file_sets.first
            expect(file_set).to be_authenticated_only_access
          end
        end
      end

      context 'with multiple files file' do
        let(:file_actor) { double }
        let(:attributes) do
          FactoryGirl.attributes_for(:generic_work, visibility: visibility).tap do |a|
            a[:files] = [file, file]
          end
        end

        context 'authenticated visibility' do
          before do
            allow(CurationConcerns::TimeService).to receive(:time_in_utc) { xmas }
            allow(CurationConcerns::Actors::FileActor).to receive(:new).and_return(file_actor)
          end

          it 'stamps each file with the access rights' do
            expect(file_actor).to receive(:ingest_file).and_return(true).twice

            expect(subject.create(attributes)).to be true
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
          expect(subject.create(attributes)).to be true
          expect(curation_concern).to be_persisted
          expect(curation_concern.title).to eq ['this is present']
        end
      end
    end
  end

  describe '#update' do
    let(:curation_concern) { create(:generic_work, user: user) }

    context 'failure' do
      let(:attributes) { {} }

      it 'returns false' do
        expect_any_instance_of(described_class).to receive(:save).and_return(false)
        expect(subject.update(attributes)).to be false
      end
    end

    context 'success' do
      it "invokes the after_update_metadata callback" do
        expect(CurationConcerns.config.callback).to receive(:run)
          .with(:after_update_metadata, curation_concern, user)
        subject.update(title: ['Other Title'])
      end
    end

    context 'with in_works_ids' do
      let(:parent) { FactoryGirl.create(:generic_work) }
      let(:old_parent) { FactoryGirl.create(:generic_work) }
      let(:attributes) do
        FactoryGirl.attributes_for(:generic_work).merge(
          in_works_ids: [parent.id]
        )
      end
      before do
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
        old_parent.ordered_members << curation_concern
        old_parent.save!
      end
      it "attaches the parent" do
        expect(subject.update(attributes)).to be true
        expect(curation_concern.in_works).to eq [parent]

        expect(old_parent.reload.members).to eq []
      end
    end
    context 'without in_works_ids' do
      let(:old_parent) { FactoryGirl.create(:generic_work) }
      let(:attributes) do
        FactoryGirl.attributes_for(:generic_work).merge(
          in_works_ids: []
        )
      end
      before do
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
        old_parent.ordered_members << curation_concern
        old_parent.save!
      end
      it "removes the old parent" do
        expect(subject.update(attributes)).to be true
        expect(curation_concern.in_works).to eq []
        expect(old_parent.reload.members).to eq []
      end
    end
    context 'with nil in_works_ids' do
      let(:parent) { FactoryGirl.create(:generic_work) }
      let(:attributes) do
        FactoryGirl.attributes_for(:generic_work).merge(
          in_works_ids: nil
        )
      end
      before do
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
        parent.ordered_members << curation_concern
        parent.save!
      end
      it "does nothing" do
        expect(subject.update(attributes)).to be true
        expect(curation_concern.in_works).to eq [parent]
      end
    end
    context 'adding to collections' do
      let!(:collection1) { create(:collection, user: user) }
      let!(:collection2) { create(:collection, user: user) }
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

        expect(subject.update(attributes)).to be true

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
      let(:curation_concern) { create(:generic_work, user: user, ordered_members: [file_set1, file_set2]) }
      let(:attributes) do
        FactoryGirl.attributes_for(:generic_work, ordered_member_ids: [file_set2.id, file_set1.id])
      end
      it 'updates the order of file sets' do
        expect(curation_concern.ordered_members.to_a).to eq [file_set1, file_set2]
        expect(subject.update(attributes)).to be true

        curation_concern.reload
        expect(curation_concern.ordered_members.to_a).to eq [file_set2, file_set1]
      end
      ## Is this something we want to support?
      context "when told to stop ordering a file set" do
        let(:attributes) do
          FactoryGirl.attributes_for(:generic_work, ordered_member_ids: [file_set2.id])
        end
        it "works" do
          expect(curation_concern.ordered_members.to_a).to eq [file_set1, file_set2]

          expect(subject.update(attributes)).to be true

          curation_concern.reload
          expect(curation_concern.ordered_members.to_a).to eq [file_set2]
        end
      end
    end
  end
end
