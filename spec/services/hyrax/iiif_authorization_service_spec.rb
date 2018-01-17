RSpec.describe Hyrax::IIIFAuthorizationService do
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:controller) { double(current_ability: ability) }
  let(:service) { described_class.new(controller) }
  let(:image_id) { '0b957460-99b4-4c31-902f-0fc23eefb972' }
  let(:image) { Riiif::Image.new(image_id) }
  let(:file_node) { instance_double(Hyrax::FileNode) }
  let(:file_set) { instance_double(FileSet) }

  before do
    allow(Hyrax::Queries).to receive(:find_by).with(id: Valkyrie::ID.new(image_id)).and_return(file_node)
    allow(Hyrax::Queries).to receive(:find_parents).with(resource: file_node).and_return(file_set)
  end

  describe '#can?' do
    context "when the user has read access to the FileSet" do
      before { allow(ability).to receive(:can?).with(:show, file_set).and_return(true) }

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
      before { allow(ability).to receive(:can?).with(:show, file_set).and_return(false) }

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
