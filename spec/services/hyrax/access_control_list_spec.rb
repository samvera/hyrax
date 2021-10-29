# frozen_string_literal: true

require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::AccessControlList do
  subject(:acl) do
    described_class.new(resource: resource,
                        persister: persister,
                        query_service: query_service)
  end

  let(:permission)    { FactoryBot.build(:permission) }
  let(:adapter)       { Valkyrie::MetadataAdapter.find(:test_adapter) }
  let(:persister)     { adapter.persister }
  let(:query_service) { adapter.query_service }

  let(:resource) do
    r = build(:hyrax_resource)
    Hyrax.persister.save(resource: r)
  end

  describe 'grant DSL' do
    let(:mode)  { :read }
    let(:user)  { ::User.find_by_user_key(permission.agent) }
    let(:group) { Hyrax::Group.new('public') }

    describe '#grant' do
      it 'grants a permission' do
        expect { acl.grant(mode).to(user) }
          .to change { acl.permissions }
          .to contain_exactly(have_attributes(mode: mode,
                                              agent: user.user_key.to_s,
                                              access_to: resource.id))
      end

      it 'grants a permission to a group' do
        expect { acl.grant(mode).to(group) }
          .to change { acl.permissions }
          .to contain_exactly(have_attributes(mode: mode,
                                              agent: "group/#{group.name}",
                                              access_to: resource.id))
      end
    end

    describe '#revoke' do
      before do
        acl << permission
        acl.save
      end

      it 'revokes a permission' do
        expect { acl.revoke(mode).from(user) }
          .to change { acl.permissions }
          .to be_empty
      end
    end
  end

  describe '#permissions' do
    it 'is empty by default' do
      expect(acl.permissions).to be_empty
    end
  end

  describe '#permissions=' do
    let(:group) { Hyrax::Group.new('public') }

    before { acl.grant(:read).to(group) }

    it 'sets the permissions with access_to' do
      expect { acl.permissions = [permission] }
        .to change { acl.permissions }
        .to contain_exactly(have_attributes(mode: permission.mode,
                                            agent: permission.agent,
                                            access_to: resource.id))
    end
  end

  describe '#<<' do
    it 'adds the new permission with access_to' do
      expect { acl << permission }
        .to change { acl.permissions }
        .to contain_exactly(have_attributes(mode: permission.mode,
                                            agent: permission.agent,
                                            access_to: resource.id))
    end
  end

  describe '#delete' do
    it 'does nothing when the permission is not in the set' do
      expect { acl.delete(permission) }
        .not_to change { acl.permissions }
        .from be_empty
    end

    context 'when the permission exists' do
      before { acl << permission }

      it 'removes the permission' do
        expect { acl.delete(permission) }
          .to change { acl.permissions }
          .from(contain_exactly(have_attributes(mode: permission.mode,
                                                agent: permission.agent,
                                                access_to: resource.id)))
          .to be_empty
      end
    end
  end

  describe '#save' do
    let(:listener) { Hyrax::Specs::SpyListener.new }

    before { Hyrax.publisher.subscribe(listener) }
    after  { Hyrax.publisher.unsubscribe(listener) }

    it 'leaves permissions unchanged by default' do
      expect { acl.save }
        .not_to change { acl.permissions }
        .from be_empty
    end

    it 'does not publish when permissions are unchanged' do
      expect { acl.save }
        .not_to change { listener.object_acl_updated }
        .from nil
    end

    context 'with additions' do
      let(:permissions)      { [permission, other_permission] }
      let(:other_permission) { build(:permission, mode: 'edit') }

      before { permissions.each { |p| acl << p } }

      it 'saves the permission policies' do
        expect { acl.save }
          .to change { Hyrax::AccessControl.for(resource: resource, query_service: acl.query_service).permissions }
          .to contain_exactly(*permissions)
      end

      it 'publishes a successful event' do
        expect { acl.save }
          .to change { listener.object_acl_updated&.payload }
          .to include(result: :success)
      end

      context 'when resource is not saved' do
        context 'and resource is :hyrax_resource' do
          let(:resource) { FactoryBot.build(:hyrax_resource) }
          it 'does not save the permission policies' do
            expect { acl.save }
              .not_to change { Hyrax::AccessControl.for(resource: resource, query_service: acl.query_service).permissions }
          end
        end

        context 'and resource is any other model' do
          let(:resource) { FactoryBot.build(:hyrax_admin_set) } # same error for :hyrax_collection
          it 'does not save the permission policies' do
            pending 'error occurs when the resource is a :hyrax_work, :hyrax_collection, or :hyrax_admin_set'
            expect { acl.save }
              .not_to change { Hyrax::AccessControl.for(resource: resource, query_service: acl.query_service).permissions }
          end
        end
      end
    end

    context 'with deletions' do
      let(:permissions)      { [permission, other_permission] }
      let(:other_permission) { build(:permission, mode: 'edit') }

      before do
        permissions.each { |p| acl << p }
        acl.save
      end

      it 'deletes the permission policy' do
        delete_me = acl.permissions.first
        acl.delete(delete_me)
        rest = acl.permissions.clone

        expect { acl.save }
          .to change { Hyrax::AccessControl.for(resource: resource, query_service: acl.query_service).permissions }
          .to contain_exactly(*rest)
      end
    end
  end
end
