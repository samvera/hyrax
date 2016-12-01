require 'spec_helper'
require 'cancan/matchers'

describe 'User' do
  describe 'Abilities' do
    subject { ability }
    let(:ability) { Ability.new(current_user) }
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    let(:creating_user) { create(:user) }
    let(:user) { create(:user) }
    let(:current_user) { user }
    let(:collection) { create(:collection, visibility: visibility, user: creating_user) }
    before do
      collection.visibility = visibility
      collection.save
    end
    describe 'the collection creator' do
      let(:current_user) { creating_user }
      it do
        is_expected.to be_able_to(:create, ::Collection.new)
        is_expected.to be_able_to(:create, ::Collection)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:update, collection)
        is_expected.to be_able_to(:destroy, collection)
      end
    end

    describe 'another authenticated user' do
      it do
        is_expected.to be_able_to(:create, ::Collection.new)
        is_expected.to be_able_to(:create, ::Collection)
        is_expected.not_to be_able_to(:read, collection)
        is_expected.not_to be_able_to(:update, collection)
        is_expected.not_to be_able_to(:destroy, collection)
      end
    end

    describe 'a nil user' do
      let(:current_user) { nil }
      it do
        is_expected.not_to be_able_to(:create, ::Collection.new)
        is_expected.not_to be_able_to(:read, collection)
        is_expected.not_to be_able_to(:update, collection)
        is_expected.not_to be_able_to(:destroy, collection)
      end
    end
  end
end
