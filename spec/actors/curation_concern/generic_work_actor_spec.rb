require 'spec_helper'

describe Sufia::CurationConcern::GenericWorkActor do
  include ActionDispatch::TestProcess # for fixture_file_upload
  include Sufia::Noid

  let(:user) { FactoryGirl.create(:user) }
  let(:file) { fixture_file_upload('/world.png','image/png') }
  let(:generic_file) do
    GenericFile.create do |gf|
      gf.apply_depositor_metadata(user)
    end
  end
  let(:actor)      { Sufia::GenericFile::Actor.new(generic_file, user) }

  subject {
    Worthwhile::CurationConcern.actor(curation_concern, user, attributes)
  }

  describe '#create' do
    let(:curation_concern) { Sufia::Works::GenericWork.new(id: assign_id )}

    context 'failure' do
      let(:attributes) {{}}

      it 'returns false' do
        expect_any_instance_of( CurationConcern::GenericWorkActor).to receive(:save).and_return(false)
        allow(subject).to receive(:attach_files).and_return(true)
        expect(subject.create).to be false
      end
    end

    context 'valid attributes' do
      before do
      end
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }

      context 'with a file' do
        let(:attributes) {
          FactoryGirl.attributes_for(:generic_work, visibility: visibility).tap {|a|
            a[:files] = file
          }
        }

        context 'authenticated visibility' do
          it 'should stamp each file with the access rights' do
            s2 = double('characterize job')
            s3 = double('content deposit job')
            allow(CharacterizeJob).to receive(:new).and_return(s2)
            allow(ContentDepositEventJob).to receive(:new).and_return(s3)
            expect(Sufia.queue).to receive(:push).with(s3).once
            expect(Sufia.queue).to receive(:push).with(s2).once
            expect(subject.create).to be true
            expect(curation_concern).to be_persisted
            expect(curation_concern.date_uploaded).to eq Date.today
            expect(curation_concern.date_modified).to eq Date.today
            expect(curation_concern.depositor).to eq user.user_key

            expect(curation_concern.generic_file_ids.count).to eq 1
            expect(curation_concern.generic_files.first.work).to eq curation_concern
            # Sanity test to make sure the file we uploaded is stored and has same permission as parent.
            generic_file = curation_concern.generic_files.first
            file.rewind
            expect(generic_file.content.content).to eq file.read

          end
        end
      end

      context 'with multiple files file' do
        let(:attributes) {
          FactoryGirl.attributes_for(:generic_work, visibility: visibility).tap {|a|
            a[:files] = [file, file]
          }
        }

        context 'authenticated visibility' do
          it 'should stamp each file with the access rights' do
            s2 = double('characterize job')
            s3 = double('content deposit job')
            allow(CharacterizeJob).to receive(:new).and_return(s2)
            allow(ContentDepositEventJob).to receive(:new).and_return(s3)
            expect(Sufia.queue).to receive(:push).with(s3).twice
            expect(Sufia.queue).to receive(:push).with(s2).twice

            expect(subject.create).to be true
            expect(curation_concern).to be_persisted
            expect(curation_concern.date_uploaded).to eq Date.today
            expect(curation_concern.date_modified).to eq Date.today
            expect(curation_concern.depositor).to eq user.user_key

            expect(curation_concern.generic_file_ids.count).to eq 2
            # Sanity test to make sure the file we uploaded is stored and has same permission as parent.

          end
        end
      end

      context "with a present and a blank title" do
        let(:attributes) {
          FactoryGirl.attributes_for(:generic_work, title: ['this is present', ''])
        }

        it 'should stamp each link with the access rights' do
          expect(subject.create).to be true
          expect(curation_concern).to be_persisted
          expect(curation_concern.title).to eq ['this is present']
        end
      end
    end
  end

  describe '#update' do
    let(:curation_concern) { FactoryGirl.create(:generic_work, user: user)}

    context 'failure' do
      let(:attributes) {{}}

      it 'returns false' do
        expect_any_instance_of(CurationConcern::GenericWorkActor).to receive(:save).and_return(false)
        expect(subject.update).to be false
      end
    end

    context 'valid attributes' do
      let(:attributes) {{}}
      it "should interpret and apply embargo and lease visibility settings" do
#        expect(subject).to receive(:interpret_lease_visibility).and_return(true)
#        expect(subject).to receive(:interpret_embargo_visibility).and_return(true)
        subject.update
      end
    end

    context 'adding to collections' do
      let!(:collection1) { FactoryGirl.create(:collection, user: user) }
      let!(:collection2) { FactoryGirl.create(:collection, user: user) }
      let(:attributes) {
        FactoryGirl.attributes_for(:generic_work,
                                   visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
                                   collection_ids: [collection2.id])
      }
      before do
        curation_concern.apply_depositor_metadata(user.user_key)
        curation_concern.save!
        collection1.members = [curation_concern]
        collection1.save!
      end

      it "should add to collections" do
        reload = Sufia::Works::GenericWork.find(curation_concern.id)
        expect(reload.collections).to eq [collection1]

        expect(subject.update).to be true

        reload = Sufia::Works::GenericWork.find(curation_concern.id)
        expect(reload.identifier).to be_blank
        expect(reload).to be_persisted
        expect(reload.collections.count).to eq 1
        expect(reload.collections).to eq [collection2]
      end
    end
  end
end
