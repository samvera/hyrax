# frozen_string_literal: true

return unless defined? Hyrax::Actors::GenericWorkActor

require 'redlock'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Actors::GenericWorkActor, :active_fedora do
  include ActionDispatch::TestProcess
  let(:env) { Hyrax::Actors::Environment.new(curation_concern, ability, attributes) }
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:admin_set) { create(:admin_set, id: 'admin_set_1', with_permission_template: { with_active_workflow: true }) }
  # stub out redis connection
  let(:redlock_client_stub) do
    client = double('redlock client')
    allow(client).to receive(:lock).and_yield(true)
    allow(Redlock::Client).to receive(:new).and_return(client)
    client
  end

  let(:listener) { Hyrax::Specs::SpyListener.new }

  before { Hyrax.publisher.subscribe(listener) }
  after  { Hyrax.publisher.unsubscribe(listener) }

  subject { Hyrax::CurationConcern.actor }

  describe '#create' do
    let(:curation_concern) { create(:generic_work, user: user) }
    let(:xmas) { DateTime.parse('2014-12-25 11:30') }
    let(:attributes) { {} }
    let(:file) { fixture_file_upload('/world.png', 'image/png') }
    let(:uploaded_file) { Hyrax::UploadedFile.create(file: file, user: user) }
    let(:terminator) { Hyrax::Actors::Terminator.new }

    subject(:middleware) do
      stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
        middleware.use Hyrax::Actors::CreateWithFilesActor
        middleware.use Hyrax::Actors::AddToWorkActor
        middleware.use Hyrax::Actors::InterpretVisibilityActor
        middleware.use described_class
      end
      stack.build(terminator)
    end

    before do
      allow(terminator).to receive(:create).and_return(true)
    end

    context 'failure' do
      before { allow_any_instance_of(described_class).to receive(:save).and_return(false) }

      it 'returns false' do
        expect(middleware.create(env)).to be false
      end
    end

    context 'success' do
      before do
        redlock_client_stub
      end
      let(:attributes) { { title: ['Foo Bar'], admin_set_id: admin_set.id } }

      it 'publishes an object.deposited event' do
        expect { middleware.create(env) }
          .to change { listener.object_deposited&.payload }
          .to eq object: curation_concern, user: user
      end

      it 'publishes an object.metadata.updated event' do
        expect { middleware.create(env) }
          .to change { listener.object_metadata_updated&.payload }
          .to eq object: curation_concern, user: user
      end
    end

    context 'valid attributes', perform_enqueued: [AttachFilesToWorkJob, IngestJob] do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }

      before { redlock_client_stub }

      context 'with embargo' do
        context "with attached files" do
          let(:date) { Time.zone.today + 2 }
          let(:uploaded_file_ids) { [uploaded_file.id] }
          let(:attributes) do
            { title: ['New embargo'], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
              visibility_during_embargo: 'authenticated', embargo_release_date: date.to_s,
              visibility_after_embargo: 'open', visibility_during_lease: 'open',
              lease_expiration_date: '2014-06-12', visibility_after_lease: 'restricted',
              admin_set_id: admin_set.id,
              uploaded_files: uploaded_file_ids,
              license: ['http://creativecommons.org/licenses/by/3.0/us/'] }
          end

          it "applies embargo to attached files" do
            middleware.create(env)
            curation_concern.reload
            file_set = curation_concern.file_sets.first
            expect(file_set).to be_persisted
            expect(file_set.visibility_during_embargo).to eq 'authenticated'
            expect(file_set.visibility_after_embargo).to eq 'open'
            expect(file_set.visibility).to eq 'authenticated'
          end
        end
      end

      context 'with in_work_ids' do
        let(:parent) { create(:generic_work, user: user) }
        let(:attributes) do
          attributes_for(:generic_work, visibility: visibility, admin_set_id: admin_set.id).merge(
            in_works_ids: [parent.id]
          )
        end

        it "attaches the parent" do
          allow_any_instance_of(Hyrax::Actors::AddToWorkActor).to receive(:can_edit_both_works?).and_return(true)
          expect(middleware.create(env)).to be true
          expect(curation_concern.reload.in_works).to eq [parent]
        end
        it "does not attach the parent" do
          allow_any_instance_of(Hyrax::Actors::AddToWorkActor).to receive(:can_edit_both_works?).and_return(false)
          expect(middleware.create(env)).to be false
          expect(curation_concern.reload.in_works).to eq []
        end
      end

      context 'with a file' do
        let(:attributes) do
          attributes_for(:generic_work, admin_set_id: admin_set.id, visibility: visibility).tap do |a|
            a[:uploaded_files] = [uploaded_file.id]
          end
        end

        context 'authenticated visibility' do
          let(:file_actor) { double }

          before do
            allow(Hyrax::TimeService).to receive(:time_in_utc) { xmas }
            allow(Hyrax::Actors::FileActor).to receive(:new).and_return(file_actor)
          end

          it 'stamps each file with the access rights and runs publishes events' do
            expect(file_actor).to receive(:ingest_file).and_return(true)
            expect(middleware.create(env)).to be true
            expect(listener.object_deposited.payload).to eq object: env.curation_concern, user: user
            expect(listener.file_set_attached.payload).to match file_set: an_instance_of(FileSet), user: user
            curation_concern.reload
            expect(curation_concern).to be_persisted
            expect(curation_concern.date_uploaded).to eq xmas
            expect(curation_concern.date_modified).to eq xmas
            expect(curation_concern.depositor).to eq user.user_key
            expect(curation_concern.representative).not_to be_nil
            expect(curation_concern.file_sets.size).to eq 1
            expect(curation_concern).to be_authenticated_only_access
            # Sanity test to make sure the file_set has same permission as parent.
            file_set = curation_concern.file_sets.first
            expect(file_set).to be_authenticated_only_access
          end
        end

        context 'setting file set visibility different than work' do
          let(:attributes) do
            attributes_for(:generic_work, admin_set_id: admin_set.id, visibility: work_visibility).tap do |a|
              a[:uploaded_files] = [uploaded_file.id]
              a[:file_set] = [{ visibility: file_set_visibility, uploaded_file_id: uploaded_file.id }]
            end
          end
          let(:file_actor) { double }
          let(:work_visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
          let(:file_set_visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

          before do
            allow(Hyrax::TimeService).to receive(:time_in_utc) { xmas }
            allow(Hyrax::Actors::FileActor).to receive(:new).and_return(file_actor)
          end

          it 'sets file set with requested access rights' do
            expect(file_actor).to receive(:ingest_file).and_return(true)
            expect(middleware.create(env)).to be true
            curation_concern.reload
            expect(curation_concern).to be_persisted
            expect(curation_concern.file_sets.size).to eq 1
            expect(curation_concern).to be_open_access
            file_set = curation_concern.file_sets.first
            expect(file_set).to be_private_access
          end
        end
      end

      context 'with multiple files' do
        let(:file_actor) { double }
        let(:uploaded_file2) { Hyrax::UploadedFile.create(file: file, user: user) }
        let(:attributes) do
          attributes_for(:generic_work, admin_set_id: admin_set.id, visibility: visibility).tap do |a|
            a[:uploaded_files] = [uploaded_file.id, uploaded_file2.id]
          end
        end

        context 'authenticated visibility' do
          before do
            allow(Hyrax::TimeService).to receive(:time_in_utc) { xmas }
            allow(Hyrax::Actors::FileActor).to receive(:new).and_return(file_actor)
          end

          it 'stamps each file with the access rights' do
            expect(file_actor).to receive(:ingest_file).and_return(true).twice

            expect(middleware.create(env)).to be true
            curation_concern.reload
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
          attributes_for(:generic_work, admin_set_id: admin_set.id, title: ['this is present', ''])
        end

        it 'stamps each link with the access rights' do
          expect(middleware.create(env)).to be true
          expect(curation_concern).to be_persisted
          expect(curation_concern.title).to eq ['this is present']
        end
      end
    end
  end

  describe '#update' do
    let(:curation_concern) { create(:generic_work, user: user, admin_set_id: admin_set.id) }

    context 'failure' do
      let(:attributes) { {} }

      it 'returns false' do
        expect(curation_concern).to receive(:save).and_return(false)
        expect(subject.update(env)).to be false
      end
    end

    context 'success' do
      let(:attributes) { { title: ['Other Title'] } }

      it "invokes the after_update_metadata callback" do
        expect { subject.update(env) }
          .to change { listener.object_metadata_updated&.payload }
          .to eq object: curation_concern, user: user
      end
    end

    context 'with in_works_ids' do
      let(:parent) { create(:generic_work, user: user) }
      let(:old_parent) { create(:generic_work, user: user) }
      let(:attributes) do
        attributes_for(:generic_work).merge(
          in_works_ids: [parent.id]
        )
      end

      before do
        old_parent.ordered_members << curation_concern
        old_parent.save!
      end
      it "attaches the parent" do
        expect(subject.update(env)).to be true
        expect(curation_concern.in_works).to eq [parent]
        expect(old_parent.reload.members).to eq []
      end
    end

    context 'without in_works_ids' do
      let(:old_parent) { create(:generic_work) }
      let(:attributes) do
        attributes_for(:generic_work).merge(
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
        allow(curation_concern).to receive(:depositor).and_return(old_parent.depositor)
        expect(subject.update(env)).to be true
        expect(curation_concern.in_works).to eq []
        expect(old_parent.reload.members).to eq []
      end
    end

    context 'with nil in_works_ids' do
      let(:parent) { create(:generic_work) }
      let(:attributes) do
        attributes_for(:generic_work).merge(
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
        expect(subject.update(env)).to be true
        expect(curation_concern.in_works).to eq [parent]
      end
    end

    context 'with multiple file sets' do
      let(:file_set1) { create(:file_set) }
      let(:file_set2) { create(:file_set) }
      let(:curation_concern) { create(:generic_work, user: user, ordered_members: [file_set1, file_set2], admin_set_id: admin_set.id) }
      let(:attributes) do
        attributes_for(:generic_work, ordered_member_ids: [file_set2.id, file_set1.id])
      end

      it 'updates the order of file sets' do
        expect(curation_concern.ordered_members.to_a).to eq [file_set1, file_set2]
        expect(subject.update(env)).to be true

        curation_concern.reload
        expect(curation_concern.ordered_members.to_a).to eq [file_set2, file_set1]
      end
      ## Is this something we want to support?
      context "when told to stop ordering a file set" do
        let(:attributes) do
          attributes_for(:generic_work, ordered_member_ids: [file_set2.id])
        end

        it "works" do
          expect(curation_concern.ordered_members.to_a).to eq [file_set1, file_set2]

          expect(subject.update(env)).to be true

          curation_concern.reload
          expect(curation_concern.ordered_members.to_a).to eq [file_set2]
        end
      end
    end
  end
end
