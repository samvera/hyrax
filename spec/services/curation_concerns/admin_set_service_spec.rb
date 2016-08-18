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
    subject { service.select_options }
    it { is_expected.to eq [['foo', as1.id],
                            ['bar', as2.id]] }
  end
end
