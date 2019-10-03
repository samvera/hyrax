require 'valkyrie/specs/shared_specs'
require 'hyrax/specs/shared_specs/metadata'

RSpec.shared_examples 'a Hyrax::Resource' do
  subject(:resource) { described_class.new }
  let(:adapter)      { Valkyrie::Persistence::Memory::MetadataAdapter.new }

  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  describe '#alternate_ids' do
    let(:id) { Valkyrie::ID.new('fake_identifier') }

    it 'has an attribute for alternate ids' do
      expect { resource.alternate_ids = id }
        .to change { resource.alternate_ids }
        .to contain_exactly id
    end
  end

  it { is_expected.to respond_to :collection? }
  it { is_expected.to respond_to :file? }
  it { is_expected.to respond_to :file_set? }
  it { is_expected.to respond_to :pcdm_object? }
  it { is_expected.to respond_to :work? }
end

RSpec.shared_examples 'a Hyrax::Work' do
  it_behaves_like 'a Hyrax::Resource'
  it_behaves_like 'a model with core metadata'

  it { is_expected.not_to be_collection }
  it { is_expected.not_to be_file }
  it { is_expected.not_to be_file_set }
  it { is_expected.to be_pcdm_object }
  it { is_expected.to be_work }
end
