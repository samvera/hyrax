require 'spec_helper'

RSpec.describe CurationConcerns::AdminSetService do
  describe ".select_options" do
    let(:service) { described_class.new(user) }
    let(:user) { create(:user) }
    let!(:as1) { create(:admin_set, :public, title: ['foo']) }
    let!(:as2) { create(:admin_set, :public, title: ['bar']) }
    subject { service.select_options }
    it { is_expected.to eq [['foo', as1.id],
                            ['bar', as2.id]] }
  end
end
