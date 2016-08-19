require 'spec_helper'

RSpec.describe CurationConcerns::AdminSetService do
  describe ".select_options" do
    let(:controller) { ::CatalogController.new }

    let(:context) do
      double(current_ability: Ability.new(user),
             repository: controller.repository,
             blacklight_config: controller.blacklight_config)
    end
    let(:service) { described_class.new(context) }
    let(:user) { create(:user) }
    let!(:as1) { create(:admin_set, :public, title: ['foo']) }
    let!(:as2) { create(:admin_set, :public, title: ['bar']) }
    let!(:as3) { create(:admin_set, edit_users: [user.user_key], title: ['baz']) }

    context "with default (read) access" do
      subject { service.select_options }
      it { is_expected.to eq [['foo', as1.id],
                              ['bar', as2.id],
                              ['baz', as3.id]] }
    end

    context "with explicit read access" do
      subject { service.select_options(:read) }
      it { is_expected.to eq [['foo', as1.id],
                              ['bar', as2.id],
                              ['baz', as3.id]] }
    end

    context "with explicit edit access" do
      subject { service.select_options(:edit) }
      it { is_expected.to eq [['baz', as3.id]] }
    end
  end
end
