require 'spec_helper'

describe Sufia::Arkivo::SchemaValidator do
  let(:item) { JSON.parse(FactoryGirl.json(:post_item)) }

  it 'ensures a token is included' do
    expect {
      described_class.new(item.except('token')).call
    }.to raise_error(Sufia::Arkivo::InvalidItem, /required property of 'token'/)
  end

  it 'ensures a metadata section is included' do
    expect {
      described_class.new(item.except('metadata')).call
    }.to raise_error(Sufia::Arkivo::InvalidItem, /required property of 'metadata'/)
  end

  it 'ensures a file section is included' do
    expect {
      described_class.new(item.except('file')).call
    }.to raise_error(Sufia::Arkivo::InvalidItem, /required property of 'file'/)
  end

  it 'ensures the metadata has a title' do
    item['metadata'].delete('title')
    expect {
      described_class.new(item).call
    }.to raise_error(Sufia::Arkivo::InvalidItem, /required property of 'title'/)
  end

  it 'ensures the metadata has rights' do
    item['metadata'].delete('rights')
    expect {
      described_class.new(item).call
    }.to raise_error(Sufia::Arkivo::InvalidItem, /required property of 'rights'/)
  end

  it 'ensures the file has a b64-encoded content' do
    item['file'].delete('base64')
    expect {
      described_class.new(item).call
    }.to raise_error(Sufia::Arkivo::InvalidItem, /required property of 'base64'/)
  end

  it 'ensures the file has a checksum' do
    item['file'].delete('md5')
    expect {
      described_class.new(item).call
    }.to raise_error(Sufia::Arkivo::InvalidItem, /required property of 'md5'/)
  end

  it 'ensures the file has a filename' do
    item['file'].delete('filename')
    expect {
      described_class.new(item).call
    }.to raise_error(Sufia::Arkivo::InvalidItem, /required property of 'filename'/)
  end

  it 'ensures the file has a content type' do
    item['file'].delete('contentType')
    expect {
      described_class.new(item).call
    }.to raise_error(Sufia::Arkivo::InvalidItem, /required property of 'contentType'/)
  end
end
