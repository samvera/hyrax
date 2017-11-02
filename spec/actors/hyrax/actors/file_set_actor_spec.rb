require 'redlock'

RSpec.describe Hyrax::Actors::FileSetActor do
  include ActionDispatch::TestProcess

  let(:user)          { create(:user) }
  let(:file_path)     { File.join(fixture_path, 'world.png') }
  let(:file)          { fixture_file_upload('world.png', 'image/png') } # we will override for the different types of File objects
  let(:local_file)    { File.open(file_path) }
  # TODO: add let(:file_set) { create_for_repository(:file_set) } ?
  let(:file_set)      { create_for_repository(:file_set, content: file) }
  let(:actor)         { described_class.new(file_set, user) }
  let(:relation)      { :original_file }
  let(:file_actor)    { Hyrax::Actors::FileActor.new(file_set, relation, user) }

  before { allow(CharacterizeJob).to receive(:perform_later) } # not testing that

  describe "#attach_to_work" do
    let(:work) { create_for_repository(:work, :public) }

    before do
      allow(actor).to receive(:acquire_lock_for).and_yield
    end

    it 'copies file_set visibility from the parent' do
      actor.attach_to_work(work)
      reloaded = Hyrax::Queries.find_by(id: file_set.id)
      expect(reloaded.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    context 'without representative and thumbnail' do
      it 'assigns them (with persistence)' do
        actor.attach_to_work(work)
        reloaded = Hyrax::Queries.find_by(id: work.id)
        expect(reloaded.representative_id).to eq(file_set.id)
        expect(reloaded.thumbnail_id).to eq(file_set.id)
      end
    end

    context 'with representative and thumbnail' do
      let(:work) { create_for_repository(:work, :public, thumbnail_id: 'ab123c78h', representative_id: 'zz365c78h') }

      it 'does not (re)assign them' do
        actor.attach_to_work(work)
        reloaded = Hyrax::Queries.find_by(id: work.id)
        expect(reloaded.representative_id).to eq(Valkyrie::ID.new('zz365c78h'))
        expect(reloaded.thumbnail_id).to eq(Valkyrie::ID.new('ab123c78h'))
      end
    end

    context 'with multiple versions' do
      let(:persister) { Valkyrie.config.metadata_adapter.persister }
      let(:work_v1) { create_for_repository(:work) } # this version of the work has no members

      before do # another version of the same work is saved with a member
        work_v2 = Hyrax::Queries.find_by(id: work_v1.id)
        work_v2.member_ids += [create_for_repository(:file_set).id]
        persister.save(resource: work_v2)
      end

      it "writes to the most up to date version" do
        actor.attach_to_work(work_v1)
        reloaded = Hyrax::Queries.find_by(id: work_v1.id)

        expect(reloaded.member_ids.size).to eq 2
      end
    end
  end
end
