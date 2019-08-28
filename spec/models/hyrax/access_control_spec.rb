# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::AccessControl do
  subject(:access_control) { described_class.new }
  let(:permission)         { build(:permission, access_to: Valkyrie::ID.new('moomin')) }

  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  it 'can save with default adapter' do
    expect(Hyrax.persister.save(resource: access_control)).to be_persisted
  end

  it 'saves an empty set of permissions by default' do
    saved = Hyrax.persister.save(resource: access_control)

    expect(Hyrax.query_service.find_by(id: saved.id).permissions).to be_empty
  end

  describe '#access_to' do
    let(:target_id) { Valkyrie::ID.new('moomin') }

    it 'grants access to a specific resource' do
      expect { access_control.access_to = target_id }
        .to change { access_control.access_to }
        .to target_id
    end

    context 'with permissions and target' do
      let(:access_control) { build(:access_control, :with_target) }
      let(:permission)     { access_control.permissions.first }

      it 'retains its own access_to target' do
        expect(Hyrax.persister.save(resource: access_control))
          .to have_attributes access_to: access_control.access_to
      end

      it 'retains access_to target on the created permissions' do
        expect(Hyrax.persister.save(resource: access_control))
          .to have_attributes(permissions: contain_exactly(have_attributes(mode:  permission.mode,
                                                                           agent: permission.agent,
                                                                           access_to: permission.access_to)))
      end
    end
  end

  describe '#permissions' do
    it 'maintains a list of permission policies' do
      expect { access_control.permissions = [permission] }
        .to change { access_control.permissions }
        .to contain_exactly(permission)
    end

    context 'with permissions' do
      before { access_control.permissions = [permission] }

      it 'can save with default adapter' do
        expect(Hyrax.persister.save(resource: access_control))
          .to have_attributes(permissions: contain_exactly(have_attributes(mode:  permission.mode,
                                                                           agent: permission.agent)))
      end

      xit 'can delete permissions' do
        saved = Hyrax.persister.save(resource: access_control)
        saved.permissions = []

        expect { Hyrax.persister.save(resource: saved) }
          .to change { Hyrax.query_service.find_by(id: saved.id).permissions }
          .from(contain_exactly(have_attributes(mode:  permission.mode,
                                                agent: permission.agent)))
          .to be_empty
      end
    end
  end
end
