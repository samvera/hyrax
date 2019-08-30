# frozen_string_literal: true

RSpec.describe Hyrax::VisibilityWriter do
  subject(:writer) { described_class.new(resource: resource) }
  let(:resource)   { Hyrax::Resource.new }
  let(:open)       { writer.visibility_map.visibilities.first }
  let(:auth)       { writer.visibility_map.visibilities[1] }
  let(:restricted) { writer.visibility_map.visibilities[2] }

  describe '#assign_access_for' do
    context 'when setting to public' do
      it 'adds public read group' do
        expect { writer.assign_access_for(visibility: open) }
          .to change { writer.permission_manager.read_groups.to_a }
          .to contain_exactly(writer.visibility_map[open][:permission])
      end
    end

    context 'when setting to authenticated' do
      it 'adds authenticated read group and removes public' do
        writer.assign_access_for(visibility: open)

        expect { writer.assign_access_for(visibility: auth) }
          .to change { writer.permission_manager.read_groups.to_a }
          .to contain_exactly(writer.visibility_map[auth][:permission])
      end
    end

    context 'when setting to private' do
      it 'removes public' do
        writer.assign_access_for(visibility: open)

        expect { writer.assign_access_for(visibility: restricted) }
          .to change { writer.permission_manager.read_groups.to_a }
          .to be_empty
      end

      it 'removes authenticated' do
        writer.assign_access_for(visibility: auth)

        expect { writer.assign_access_for(visibility: restricted) }
          .to change { writer.permission_manager.read_groups.to_a }
          .to be_empty
      end
    end
  end
end
