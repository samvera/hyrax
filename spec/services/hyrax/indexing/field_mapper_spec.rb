RSpec.describe Hyrax::Indexing::FieldMapper do
  subject(:field_mapper) { described_class.new }

  describe "#solr_name" do
    it "generates Solr field names" do
      expect(field_mapper.solr_name('creation_date', type: :date)).to eq('creation_date_dtsim')
      expect(field_mapper.solr_name('description')).to eq('description_tesim')
      expect(field_mapper.solr_name('abstract', :stored_searchable, type: :text)).to eq('abstract_tesim')
      expect(field_mapper.solr_name('abstract', 'stored_searchable')).to eq('abstract_stored_searchable')
      expect { field_mapper.solr_name('abstract', Date.current) }.to raise_error(Hyrax::Indexing::InvalidIndexDescriptor, 'Date is not a valid indexer_type. Use a String, Symbol or Descriptor.')
      expect(field_mapper.solr_name('subject', :stored_searchable)).to eq('subject_tesim')
    end
  end

  describe '#solr_names_and_values' do
    context 'with duplicate names and values provided' do
      it 'logs a warning' do
        allow(Hyrax.logger).to receive(:warn)
        expect(field_mapper.solr_names_and_values('subject', ['社会生物学', '社会生物学'], [:sortable])).to eq("subject_si" => "社会生物学")
        expect(Hyrax.logger).to have_received(:warn).with("Setting subject_si to `社会生物学', but it already had `社会生物学'")
      end
    end

    it 'generates pairs of Solr field names and values' do
      expect(field_mapper.solr_names_and_values('subject', '社会生物学', [:stored_searchable])).to eq('subject_tesim' => ['社会生物学'])
      expect(field_mapper.solr_names_and_values('subject', '社会生物学', [:stored_searchable, :sortable])).to eq("subject_si" => "社会生物学", "subject_tesim" => ["社会生物学"])
      expect(field_mapper.solr_names_and_values('subject', '社会生物学', [:not_stored_sortable, :sortable])).to eq("subject_si" => "社会生物学")
      expect(field_mapper.solr_names_and_values('subject', 'Habitat conservation', [:stored_searchable])).to eq("subject_tesim" => ["Habitat conservation"])
      expect(field_mapper.solr_names_and_values('serial_number', 123_456_789, [:stored_searchable])).to eq("serial_number_isim" => ["123456789"])
      current_date_time = DateTime.current
      expect(field_mapper.solr_names_and_values('creation_date', current_date_time, [:stored_searchable])).to eq("creation_date_dtsim" => [current_date_time.strftime('%Y-%m-%dT%H:%M:%S%:z')])
      expect(field_mapper.solr_names_and_values('publicly_accessible', true, [:stored_searchable])).to eq("publicly_accessible_bsi" => true)
    end
  end
end
