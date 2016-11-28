require 'spec_helper'
require 'sufia/controlled_vocabulary/importer/downloader'

RSpec.describe Sufia::ControlledVocabulary::Importer::Downloader do
  describe '.fetch' do
    let(:url) { 'http://example.org/' }
    let(:output) { double('output') }
    context 'when connection is successful' do
      let(:io) { double('io') }
      let(:stream) { 'foo' }
      before do
        allow(IO).to receive(:copy_stream).with(io, output).and_return(stream)
        allow(described_class).to receive(:open).with(url).and_yield(io)
      end
      it 'returns an IO stream' do
        expect(described_class.fetch(url, output)).to eq stream
      end
    end
    context 'when connection is unsuccessful' do
      let(:exception_io) { double('io', read: '') }
      before do
        allow(described_class).to receive(:open).with(url) do
          raise OpenURI::HTTPError.new('', exception_io)
        end
      end
      it 'raises an exception' do
        expect { described_class.fetch(url, output) }.to raise_error(RuntimeError, "Unable to download from #{url}\n: ")
      end
    end
  end
end
