RSpec.describe Hyrax::Actors::InterpretVisibilityActor do
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { { admin_set_id: admin_set.id } }
  let(:admin_set) { create_for_repository(:admin_set) }
  let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:one_year_from_today) { Time.zone.today + 1.year }
  let(:two_years_from_today) { Time.zone.today + 2.years }
  let(:date) { Time.zone.today + 2 }
  let(:change_set) { GenericWorkChangeSet.new(curation_concern) }
  let(:change_set_persister) { Hyrax::ChangeSetPersister.new(metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), storage_adapter: Valkyrie.config.storage_adapter) }
  let(:env) { Hyrax::Actors::Environment.new(change_set, change_set_persister, ability, attributes) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
      middleware.use Hyrax::Actors::GenericWorkActor
    end
    stack.build(terminator)
  end

  describe 'create' do
    context 'with embargo' do
      let(:attributes) do
        { title: ['New embargo'], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
          visibility_during_embargo: 'authenticated', embargo_release_date: date.to_s,
          visibility_after_embargo: 'open', visibility_during_lease: 'open',
          lease_expiration_date: '2014-06-12', visibility_after_lease: 'restricted',
          license: ['http://creativecommons.org/licenses/by/3.0/us/'] }
      end

      context 'with a valid embargo date (and no template requirements)' do
        let(:date) { Time.zone.today + 2 }

        it 'interprets and apply embargo and lease visibility settings' do
          subject.create(env)
          expect(curation_concern.visibility_during_embargo).to eq 'authenticated'
          expect(curation_concern.visibility_after_embargo).to eq 'open'
          expect(curation_concern.visibility).to eq 'authenticated'
        end
      end
    end

    context 'with lease' do
      let(:attributes) do
        { title: ['New embargo'], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
          visibility_during_embargo: 'authenticated', embargo_release_date: '2099-05-12',
          visibility_after_embargo: 'open', visibility_during_lease: 'open',
          lease_expiration_date: date.to_s, visibility_after_lease: 'restricted',
          license: ['http://creativecommons.org/licenses/by/3.0/us/'] }
      end

      context 'with a valid lease date' do
        let(:date) { Time.zone.today + 2 }

        it 'interprets and apply embargo and lease visibility settings' do
          subject.create(env)
          expect(curation_concern.embargo_release_date).to be_nil
          expect(curation_concern.visibility_during_lease).to eq 'open'
          expect(curation_concern.visibility_after_lease).to eq 'restricted'
          expect(curation_concern.visibility).to eq 'open'
        end
      end
    end
  end
end
