require 'valkyrie/specs/shared_specs/queries'

RSpec.describe Hyrax::Queries do
  let(:adapter)                  { described_class.metadata_adapter }
  let(:query_service)            { described_class.default_adapter }
  let(:persister)                { adapter.persister }
  let(:thing_that_exists)        { persister.save(resource: GenericWork.new(id: 'i_exist')) }
  let(:thing_that_used_to_exist) { persister.delete(resource: persister.save(resource: GenericWork.new(id: 'i_used_to_exist'))) }

  before do
    described_class.metadata_adapter.persister.wipe!
  end

  it_behaves_like "a Valkyrie query provider"

  it 'knows the thing that exists exists' do
    expect(described_class.exists?(thing_that_exists.id)).to be true
  end

  it 'knows the thing that used to exist does not exist' do
    expect(described_class.exists?(thing_that_used_to_exist.id)).to be false
  end

  it 'knows the thing that does not exist does not exist' do
    expect(described_class.exists?('i_do_not_exist')).to be false
  end
end
