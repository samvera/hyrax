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
        should be_able_to(:create, ::Collection.new)
        should be_able_to(:create, ::Collection)
        should be_able_to(:read, collection)
        should be_able_to(:update, collection)
        should be_able_to(:destroy, collection)
      end
    end

    describe 'another authenticated user' do
      it do
        should be_able_to(:create, ::Collection.new)
        should be_able_to(:create, ::Collection)
        should_not be_able_to(:read, collection)
        should_not be_able_to(:update, collection)
        should_not be_able_to(:destroy, collection)
      end
    end

    describe 'a nil user' do
      let(:current_user) { nil }
      it do
        should_not be_able_to(:create, ::Collection.new)
        should_not be_able_to(:read, collection)
        should_not be_able_to(:update, collection)
        should_not be_able_to(:destroy, collection)
      end
    end
  end
end
