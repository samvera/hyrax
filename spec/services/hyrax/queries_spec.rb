RSpec.describe Hyrax::Queries do
  let(:persister)                { Valkyrie.config.metadata_adapter.persister }
  let(:thing_that_exists)        { persister.save(resource: GenericWork.new(id: 'i_exist')) }
  let(:thing_that_used_to_exist) { persister.delete(resource: persister.save(resource: GenericWork.new(id: 'i_used_to_exist'))) }

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
