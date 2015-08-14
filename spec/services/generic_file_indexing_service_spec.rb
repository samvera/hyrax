require 'spec_helper'

describe CurationConcerns::GenericFileIndexingService do
  let(:generic_file) do
    GenericFile.new(
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
      resource_type: ['Book'],
      identifier: ['urn:isbn:1234567890'],
      based_near: ['Medina, Saudi Arabia'],
      related_url: ['http://example.org/TheWork/'],
      mime_type: 'image/jpeg',
      format_label: ['JPEG Image']) do |gf|
        gf.full_text.content = 'abcxyz'
      end
  end

  describe '#generate_solr_document' do
    subject { described_class.new(generic_file).generate_solr_document }

    it 'has fields' do
      expect(subject[Solrizer.solr_name('part_of')]).to be_nil
      expect(subject[Solrizer.solr_name('date_uploaded')]).to be_nil
      expect(subject[Solrizer.solr_name('date_modified')]).to be_nil
      expect(subject[Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)]).to eq '2011-01-01T00:00:00Z'
      expect(subject[Solrizer.solr_name('date_modified', :stored_sortable, type: :date)]).to eq '2012-01-01T00:00:00Z'
      expect(subject[Solrizer.solr_name('rights')]).to eq ['Wide open, buddy.']
      expect(subject[Solrizer.solr_name('related_url')]).to eq ['http://example.org/TheWork/']
      expect(subject[Solrizer.solr_name('contributor')]).to eq ['Mohammad']
      expect(subject[Solrizer.solr_name('creator')]).to eq ['Allah']
      expect(subject[Solrizer.solr_name('title')]).to eq ['The Work']
      expect(subject[Solrizer.solr_name('title', :facetable)]).to eq ['The Work']
      expect(subject[Solrizer.solr_name('description')]).to eq ['The work by Allah']
      expect(subject[Solrizer.solr_name('publisher')]).to eq ['Vertigo Comics']
      expect(subject[Solrizer.solr_name('subject')]).to eq ['Theology']
      expect(subject[Solrizer.solr_name('language')]).to eq ['Arabic']
      expect(subject[Solrizer.solr_name('date_created')]).to eq ['1200-01-01']
      expect(subject[Solrizer.solr_name('resource_type')]).to eq ['Book']
      expect(subject[Solrizer.solr_name('file_format')]).to eq 'jpeg (JPEG Image)'
      expect(subject[Solrizer.solr_name('identifier')]).to eq ['urn:isbn:1234567890']
      expect(subject[Solrizer.solr_name('based_near')]).to eq ['Medina, Saudi Arabia']
      expect(subject[Solrizer.solr_name('mime_type')]).to eq ['image/jpeg']
      expect(subject['all_text_timv']).to eq('abcxyz')
    end
  end
end
