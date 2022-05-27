# frozen_string_literal: true
RSpec.describe Hyrax::IiifAuthorizationService do
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:controller) { double(current_ability: ability) }
  let(:service) { described_class.new(controller) }
  let(:file_set_id) { 'mp48sc763' }
  let(:image_id) { "#{file_set_id}/files/0b957460-99b4-4c31-902f-0fc23eefb972" }
  let(:image) { Riiif::Image.new(image_id) }

  describe "#can?" do
    context "when the user has read access to the FileSet" do
      before { allow(ability).to receive(:test_read).with(file_set_id).and_return(true) }

      context "info" do
        subject { service.can?(:info, image) }

        it { is_expected.to be true }
      end

      context "show" do
        subject { service.can?(:show, image) }

        it { is_expected.to be true }
      end
    end

    context "when the user doesn't have read access to the FileSet" do
      before { allow(ability).to receive(:test_read).with(file_set_id).and_return(false) }

      context "info" do
        subject { service.can?(:info, image) }

        it { is_expected.to be false }
      end

      context "show" do
        subject { service.can?(:show, image) }

        it { is_expected.to be false }
      end
    end
  end
end
