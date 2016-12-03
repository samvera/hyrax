require 'spec_helper'

RSpec.describe Hyrax::CollectionsService do
  let(:controller) { ::CatalogController.new }

  let(:context) do
    double(current_ability: Ability.new(user),
           repository: controller.repository,
           blacklight_config: controller.blacklight_config)
  end

  let(:service) { described_class.new(context) }
  let(:user) { create(:user) }

  describe "#search_results" do
    subject { service.search_results(access) }
    let!(:collection1) { create(:collection, :public, title: ['foo']) }
    let!(:collection2) { create(:collection, :public, title: ['bar']) }
    let!(:collection3) { create(:collection, :public, edit_users: [user.user_key], title: ['baz']) }
    before do
      create(:admin_set, :public) # this should never be returned.
    end

    context "with read access" do
      let(:access) { :read }
      it "returns three collections" do
        expect(subject.map(&:id)).to match_array [collection1.id, collection2.id, collection3.id]
      end
    end

    context "with edit access" do
      let(:access) { :edit }
      it "returns one collections" do
        expect(subject.map(&:id)).to match_array [collection3.id]
      end
    end
  end
end
