# frozen_string_literal: true
require 'spec_helper'
require 'wings'
require 'wings/active_fedora_converter'

RSpec.describe Wings::ActiveFedoraConverter, :clean_repo do
  subject(:converter) { described_class.new(resource: resource) }
  let(:attributes)    { { id: id } }
  let(:id)            { 'moomin_id' }
  let(:resource)      { work.valkyrie_resource }
  let(:work)          { GenericWork.new(attributes) }

  describe '.convert' do
    it 'returns the ActiveFedora model' do
      expect(described_class.convert(resource: resource)).to eq work
    end
  end

  describe '#convert' do
    it 'returns the ActiveFedora model' do
      expect(converter.convert).to eq work
    end

    context 'with attributes' do
      let(:attributes) do
        FactoryBot.attributes_for(:generic_work)
      end

      it 'repopulates the attributes' do
        expect(converter.convert).to have_attributes(attributes)
      end

      it 'populates reflections'
    end

    context 'with an embargo' do
      let(:work) { FactoryBot.create(:embargoed_work) }

      it 'repopulates the embargo' do
        expect(converter.convert).to have_attributes(embargo_id: work.embargo_id)
      end

      it 'repopulates the embargo as a model' do
        expect(converter.convert).to have_attributes(embargo: work.embargo)
      end
    end

    context 'with a lease' do
      let(:work) { FactoryBot.create(:leased_work) }

      it 'repopulates the lease' do
        expect(converter.convert).to have_attributes(lease_id: work.lease_id)
      end
    end

    context 'with a generic work with _id attributes' do
      let(:work) { FactoryBot.create(:work_with_representative_file, with_admin_set: true) }
      before do
        work.thumbnail_id = work.representative_id
      end

      it 'repopulates the _id attributes' do
        expect(converter.convert).to have_attributes(
          representative_id: work.representative_id,
          thumbnail_id: work.thumbnail_id,
          access_control_id: work.access_control_id,
          admin_set_id: work.admin_set_id
        )
      end
    end

    context 'when specifying visibility' do
      let(:attributes) do
        FactoryBot.attributes_for(:generic_work)
      end

      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

      before { resource.visibility = visibility }

      it 'sets the visibility' do
        expect(converter.convert).to have_attributes(visibility: visibility)
      end

      context 'when restricted' do
        let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }

        it 'sets the visibility' do
          expect(converter.convert).to have_attributes(visibility: visibility)
        end
      end

      context 'when private' do
        let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

        it 'sets the visibility' do
          expect(converter.convert).to have_attributes(visibility: visibility)
        end
      end
    end

    context 'when setting ACLs' do
      it 'converts ACLs' do
        expect { resource.read_users = ['moomin'] }
          .to change { described_class.new(resource: resource).convert }
          .to have_attributes(read_users: contain_exactly('moomin'))
      end

      context 'when ACLs exist' do
        let(:work) { FactoryBot.create(:public_work) }

        it 'can delete ACLs' do
          expect { resource.read_groups = [] }
            .to change { described_class.new(resource: resource).convert }
            .from(have_attributes(read_groups: contain_exactly('public')))
            .to have_attributes(read_groups: be_empty)
        end
      end
    end

    context 'when converting to ACL directly' do
      let(:resource) { FactoryBot.build(:access_control) }

      context 'when empty' do
        let(:resource) { Hyrax::AccessControl.new }

        it 'gives an empty acl' do
          expect(converter.convert).to have_attributes permissions: be_empty
        end
      end

      context 'with permissions' do
        it 'converts to an ACL with permissions' do
          agent = resource.permissions.first.agent
          mode  = resource.permissions.first.mode

          expect(converter.convert)
            .to have_attributes permissions: contain_exactly(grant_permission(mode)
                                                             .to_user(agent))
        end
      end

      context 'with an #access_to grant' do
        let(:resource) { FactoryBot.build(:access_control, :with_target) }

        it 'applies the access target to permissions' do
          agent = resource.permissions.first.agent
          mode  = resource.permissions.first.mode

          expect(converter.convert)
            .to have_attributes permissions: contain_exactly(grant_permission(mode)
                                                               .on(resource.access_to)
                                                               .to_user(agent))
        end
      end

      context 'with existing access controls' do
        let(:adapter)  { Wings::Valkyrie::MetadataAdapter.new }
        let(:discover) { build(:permission, mode: :discover, access_to: resource.access_to) }
        let(:resource) { work.permission_delegate.valkyrie_resource }
        let(:work)     { create(:generic_work) }

        it 'can delete permissions' do
          resource.permissions = []

          expect(converter.convert).to have_attributes permissions: be_empty
        end

        it 'can persist deleted permissions' do
          resource.permissions = []

          expect { adapter.persister.save(resource: resource) }
            .to change { work.reload.permissions }
            .to be_empty
        end

        it 'can replace new permissions to the work' do
          resource.permissions = [discover]

          expect { adapter.persister.save(resource: resource) }
            .to change { work.reload.permissions }
            .to contain_exactly grant_permission(:discover).to_user(discover.agent).on(work.id)
        end

        it 'can persist new permissions to the work' do
          resource.permissions << discover

          expect { adapter.persister.save(resource: resource) }
            .to change { work.reload.permissions }
            .to contain_exactly(grant_permission(:discover).to_user(discover.agent).on(work.id),
                                grant_permission(:read).on(work.id),
                                grant_permission(:write).on(work.id))
        end
      end
    end

    context 'with relationships' do
      subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

      let(:resource) { subject.build }

      context 'for member_of_collections' do
        let(:pcdm_object) { collection1 }

        let(:collection1) { build(:public_collection_lw, id: 'col1', title: ['Collection 1']) }
        let(:collection2) { build(:public_collection_lw, id: 'col2', title: ['Collection 2']) }
        let(:collection3) { build(:public_collection_lw, id: 'col3', title: ['Collection 3']) }

        before do
          collection1.member_of_collections = [collection2, collection3]
          collection1.save!
        end

        it 'converts member_of_collection_ids back to af_object' do
          expect(converter.convert.member_of_collections.map(&:id)).to match_array [collection2.id, collection3.id]
        end
      end

      context 'for members' do
        let(:pcdm_object) { work1 }

        let(:work1)       { build(:work, id: 'wk1', title: ['Work 1']) }
        let(:work2)       { build(:work, id: 'wk2', title: ['Work 2']) }
        let(:work3)       { build(:work, id: 'wk3', title: ['Work 3']) }

        before do
          work1.ordered_members = [work2, work3]
          work1.save!
        end

        it 'converts member_of_collection_ids back to af_object' do
          expect(converter.convert.members.map(&:id)).to match_array [work3.id, work2.id]
        end

        it 'preserves order across conversion' do
          expect(converter.convert.ordered_member_ids).to eq [work2.id, work3.id]
        end
      end
    end
  end
end
