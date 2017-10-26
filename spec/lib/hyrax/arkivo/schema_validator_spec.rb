RSpec.describe Hyrax::Arkivo::SchemaValidator do
  let(:item) { JSON.parse(FactoryBot.json(:post_item)) }

  it 'ensures a token is included' do
    expect do
      described_class.new(item.except('token')).call
    end.to raise_error(Hyrax::Arkivo::InvalidItem, /required property of 'token'/)
  end

  it 'ensures a metadata section is included' do
    expect do
      described_class.new(item.except('metadata')).call
    end.to raise_error(Hyrax::Arkivo::InvalidItem, /required property of 'metadata'/)
  end

  it 'ensures a file section is included' do
    expect do
      described_class.new(item.except('file')).call
    end.to raise_error(Hyrax::Arkivo::InvalidItem, /required property of 'file'/)
  end

  it 'ensures the metadata has a title' do
    item['metadata'].delete('title')
    expect do
      described_class.new(item).call
    end.to raise_error(Hyrax::Arkivo::InvalidItem, /required property of 'title'/)
  end

  it 'ensures the metadata has license' do
    item['metadata'].delete('license')
    expect do
      described_class.new(item).call
    end.to raise_error(Hyrax::Arkivo::InvalidItem, /required property of 'license'/)
  end

  it 'ensures the file has a b64-encoded content' do
    item['file'].delete('base64')
    expect do
      described_class.new(item).call
    end.to raise_error(Hyrax::Arkivo::InvalidItem, /required property of 'base64'/)
  end

  it 'ensures the file has a checksum' do
    item['file'].delete('md5')
    expect do
      described_class.new(item).call
    end.to raise_error(Hyrax::Arkivo::InvalidItem, /required property of 'md5'/)
  end

  it 'ensures the file has a filename' do
    item['file'].delete('filename')
    expect do
      described_class.new(item).call
    end.to raise_error(Hyrax::Arkivo::InvalidItem, /required property of 'filename'/)
  end

  it 'ensures the file has a content type' do
    item['file'].delete('contentType')
    expect do
      described_class.new(item).call
    end.to raise_error(Hyrax::Arkivo::InvalidItem, /required property of 'contentType'/)
  end
end
