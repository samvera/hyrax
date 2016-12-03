require 'spec_helper'

describe Hyrax::FileSetIndexer do
  include Hyrax::FactoryHelpers

  let(:file_set) do
    FileSet.new(
      id: 'foo123',
      part_of: ['Arabiana'],
      contributor: ['Mohammad'],
      creator: ['Allah'],
      title: ['The Work'],
      description: ['The work by Allah'],
      publisher: ['Vertigo Comics'],
      date_created: ['1200-01-01'],
      date_uploaded: Date.parse('2011-01-01'),
      date_modified: Date.parse('2012-01-01'),
      subject: ['Theology'],
      language: ['Arabic'],
      rights: ['Wide open, buddy.'],
      rights_statement: ['No Known Copyright'],
      resource_type: ['Book'],
      identifier: ['urn:isbn:1234567890'],
      based_near: ['Medina, Saudi Arabia'],
      related_url: ['http://example.org/TheWork/']
    )
  end

  let(:mock_file) do
    mock_file_factory(
      content: "asdf",
      digest: ["urn:sha1:f794b23c0c6fe1083d0ca8b58261a078cd968967"],
      mime_type: 'image/jpeg',
      format_label: ['JPEG Image'],
      height: ['500'],
      width: ['600'],
      file_size: ['12'],
      page_count: ['1'],
      file_title: ['title'],
      duration: ['0:1'],
      sample_rate: ['sample rate']
    )
  end

  let(:mock_text) do
    mock_file_factory(content: "abcxyz")
  end

  let(:indexer) { described_class.new(file_set) }

  describe '#generate_solr_document' do
    before do
      allow(file_set).to receive(:label).and_return('CastoriaAd.tiff')
      allow(Hyrax::ThumbnailPathService).to receive(:call).and_return('/downloads/foo123?file=thumbnail')
      allow(file_set).to receive(:original_file).and_return(mock_file)
      allow(file_set).to receive(:extracted_text).and_return(mock_text)
    end
    subject { indexer.generate_solr_document }

    it 'has fields' do
      expect(subject[Solrizer.solr_name('hasRelatedMediaFragment', :symbol)]).to eq 'foo123'
      expect(subject[Solrizer.solr_name('hasRelatedImage', :symbol)]).to eq 'foo123'
      expect(subject[Solrizer.solr_name('part_of')]).to be_nil
      expect(subject[Solrizer.solr_name('date_uploaded')]).to be_nil
      expect(subject[Solrizer.solr_name('date_modified')]).to be_nil
      expect(subject[Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)]).to eq '2011-01-01T00:00:00Z'
      expect(subject[Solrizer.solr_name('date_modified', :stored_sortable, type: :date)]).to eq '2012-01-01T00:00:00Z'
      expect(subject[Solrizer.solr_name('rights')]).to eq ['Wide open, buddy.']
      expect(subject[Solrizer.solr_name('rights_statement')]).to eq ['No Known Copyright']
      expect(subject[Solrizer.solr_name('related_url')]).to eq ['http://example.org/TheWork/']
      expect(subject[Solrizer.solr_name('contributor')]).to eq ['Mohammad']
      expect(subject[Solrizer.solr_name('creator')]).to eq ['Allah']
      expect(subject[Solrizer.solr_name('title')]).to eq ['The Work']
      expect(subject[Solrizer.solr_name('title', :facetable)]).to eq ['The Work']
      expect(subject[Solrizer.solr_name('label')]).to eq 'CastoriaAd.tiff'
      expect(subject[Solrizer.solr_name('label', :stored_sortable)]).to eq 'CastoriaAd.tiff'
      expect(subject[Solrizer.solr_name('description')]).to eq ['The work by Allah']
      expect(subject[Solrizer.solr_name('publisher')]).to eq ['Vertigo Comics']
      expect(subject[Solrizer.solr_name('subject')]).to eq ['Theology']
      expect(subject[Solrizer.solr_name('language')]).to eq ['Arabic']
      expect(subject[Solrizer.solr_name('date_created')]).to eq ['1200-01-01']
      expect(subject[Solrizer.solr_name('resource_type')]).to eq ['Book']
      expect(subject[Solrizer.solr_name('file_format')]).to eq 'jpeg (JPEG Image)'
      expect(subject[Solrizer.solr_name('identifier')]).to eq ['urn:isbn:1234567890']
      expect(subject[Solrizer.solr_name('based_near')]).to eq ['Medina, Saudi Arabia']
      expect(subject.fetch('mime_type_ssi')).to eq 'image/jpeg'
      expect(subject.fetch('thumbnail_path_ss')).to eq '/downloads/foo123?file=thumbnail'
      expect(subject['all_text_timv']).to eq('abcxyz')
      expect(subject['height_is']).to eq 500
      expect(subject['width_is']).to eq 600
      expect(subject[Solrizer.solr_name('digest', :symbol)]).to eq 'urn:sha1:f794b23c0c6fe1083d0ca8b58261a078cd968967'
      expect(subject[Solrizer.solr_name('page_count')]).to eq ['1']
      expect(subject[Solrizer.solr_name('file_title')]).to eq ['title']
      expect(subject[Solrizer.solr_name('duration')]).to eq ['0:1']
      expect(subject[Solrizer.solr_name('sample_rate')]).to eq ['sample rate']
    end
  end

  describe '#file_format' do
    subject { indexer.send(:file_format) }

    context 'when both mime and format_label are present' do
      before do
        allow(file_set).to receive(:mime_type).and_return('image/png')
        allow(file_set).to receive(:format_label).and_return(['Portable Network Graphics'])
      end
      it { is_expected.to eq 'png (Portable Network Graphics)' }
    end

    context 'when just mime type is present' do
      before do
        allow(file_set).to receive(:mime_type).and_return('image/png')
        allow(file_set).to receive(:format_label).and_return([])
      end
      it { is_expected.to eq 'png' }
    end

    context 'when just format_label is present' do
      before do
        allow(file_set).to receive(:mime_type).and_return('')
        allow(file_set).to receive(:format_label).and_return(['Portable Network Graphics'])
      end
      it { is_expected.to eq ['Portable Network Graphics'] }
    end
  end
end
