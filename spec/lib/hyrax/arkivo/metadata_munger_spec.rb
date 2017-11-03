RSpec.describe Hyrax::Arkivo::MetadataMunger do
  subject { described_class.new(metadata) }

  let(:metadata) { JSON.parse(FactoryBot.json(:post_item))['metadata'] }

  it 'makes camelCase symbols into underscored strings' do
    expect(metadata).to include('resourceType', 'dateCreated', 'basedNear')
    munged = subject.call
    expect(munged).not_to include('resourceType', 'dateCreated', 'basedNear')
    expect(munged).to include('resource_type', 'date_created', 'based_near')
  end

  it 'replaces url with related_url' do
    expect(metadata).to include('url')
    munged = subject.call
    expect(munged).not_to include('url')
    expect(munged).to include('related_url')
  end

  it 'replaces tags with keyword05' do
    expect(metadata).to include('tags')
    munged = subject.call
    expect(munged).not_to include('tags')
    expect(munged).to include('keyword')
  end

  it 'replaces firstName and lastName with name' do
    expect(name_parts(metadata['creators']).count).to eq 4
    subject.call
    expect(name_parts(metadata['creators']).count).to eq 0
    expect(metadata['creators'].map { |c| c['name'] }.compact.count).to eq 4
  end

  it 'segregates creators and contributors' do
  end

  it 'deletes the original creators array' do
    expect(metadata['creators']).not_to be_nil
    munged = subject.call
    expect(munged['creators']).to be_nil
  end

  def name_parts(creators)
    creators.map { |c| c['firstName'] }.compact + creators.map { |c| c['lastName'] }.compact
  end
end
