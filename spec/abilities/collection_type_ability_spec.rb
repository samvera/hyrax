# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability do
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }

  context 'when admin user' do
    let(:user) { FactoryBot.create(:admin) }
    let(:collection_type) { create(:collection_type) }

    it 'allows all abilities' do
      is_expected.to be_able_to(:manage, Hyrax::CollectionType)
      is_expected.to be_able_to(:create, Hyrax::CollectionType)
      is_expected.to be_able_to(:edit, collection_type)
      is_expected.to be_able_to(:update, collection_type)
      is_expected.to be_able_to(:destroy, collection_type)
      is_expected.to be_able_to(:read, collection_type)
      is_expected.to be_able_to(:create_collection_of_type, collection_type)
    end
  end

  context 'when user has manage access for collection type' do
    let(:collection_type) { create(:collection_type, manager_user: user) }

    it 'allows creating collections of collection type' do
      is_expected.to be_able_to(:create_collection_of_type, collection_type)
    end

    it 'denies all abilities to collection type' do
      is_expected.not_to be_able_to(:manage, Hyrax::CollectionType)
      is_expected.not_to be_able_to(:create, Hyrax::CollectionType)
      is_expected.not_to be_able_to(:edit, collection_type)
      is_expected.not_to be_able_to(:update, collection_type)
      is_expected.not_to be_able_to(:destroy, collection_type)
      is_expected.not_to be_able_to(:read, collection_type)
    end
  end

  context 'when user has create access for collection type' do
    let!(:collection_type) { create(:collection_type, creator_user: user) }

    it 'allows creating collections of collection type' do
      is_expected.to be_able_to(:create_collection_of_type, collection_type)
    end

    it 'denies all abilities to collection type' do
      is_expected.not_to be_able_to(:manage, Hyrax::CollectionType)
      is_expected.not_to be_able_to(:create, Hyrax::CollectionType)
      is_expected.not_to be_able_to(:edit, collection_type)
      is_expected.not_to be_able_to(:update, collection_type)
      is_expected.not_to be_able_to(:destroy, collection_type)
      is_expected.not_to be_able_to(:read, collection_type)
    end
  end

  context 'when user has no special access' do
    let(:collection_type) { create(:collection_type) }

    it 'denies all abilities to collection type' do
      is_expected.not_to be_able_to(:manage, Hyrax::CollectionType)
      is_expected.not_to be_able_to(:create, Hyrax::CollectionType)
      is_expected.not_to be_able_to(:edit, collection_type)
      is_expected.not_to be_able_to(:update, collection_type)
      is_expected.not_to be_able_to(:destroy, collection_type)
      is_expected.not_to be_able_to(:read, collection_type)
      is_expected.not_to be_able_to(:create_collection_of_type, collection_type)
    end
  end
end
