# frozen_string_literal: true

RSpec.describe 'Bulkrax test application authorization', if: defined?(Bulkrax::AbilityBehavior) do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:admin) }

  before do
    allow_any_instance_of(Ability).to receive(:can_create_any_work?).and_return(true)
    allow(admin).to receive(:admin?).and_return(true)
  end

  %w[Importer Exporter].each do |resource_name|
    describe resource_name do
      let(:owned_resource) { "Bulkrax::#{resource_name}".constantize.new(user_id: owner.id) }

      it 'allows an eligible owner to read their record but not another user' do
        expect(Ability.new(owner).can?(:read, owned_resource)).to be(true)
        expect(Ability.new(other_user).can?(:read, owned_resource)).to be(false)
      end

      it 'allows an administrator to manage another user’s record' do
        expect(Ability.new(admin).can?(:manage, owned_resource)).to be(true)
      end
    end
  end
end
