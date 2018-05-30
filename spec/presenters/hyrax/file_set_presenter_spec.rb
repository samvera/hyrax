require 'iiif_manifest'

RSpec.describe Hyrax::FileSetPresenter do
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:ability) { double "Ability" }
  let(:presenter) { described_class.new(solr_document, ability) }
  let(:attributes) { file.to_solr }
  let(:file) do
    build(:file_set,
          id: '123abc',
          user: user,
          title: ["File title"],
          depositor: user.user_key,
          label: "filename.tif")
  end
  let(:user) { double(user_key: 'sarah') }

  describe 'stats_path' do
    before do
      # https://github.com/samvera/active_fedora/issues/1251
      allow(file).to receive(:persisted?).and_return(true)
    end
    it { expect(presenter.stats_path).to eq Hyrax::Engine.routes.url_helpers.stats_file_path(id: file, locale: 'en') }
  end

  subject { presenter }

  describe "#to_s" do
    subject { presenter.to_s }

    it { is_expected.to eq 'File title' }
  end

  describe "#human_readable_type" do
    subject { presenter.human_readable_type }

    it { is_expected.to eq 'File' }
  end

  describe "#model_name" do
    subject { presenter.model_name }

    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe "#to_partial_path" do
    subject { presenter.to_partial_path }

    it { is_expected.to eq 'file_sets/file_set' }
  end

  describe "office_document?" do
    subject { presenter.office_document? }

    it { is_expected.to be false }
  end

  describe "#user_can_perform_any_action?" do
    subject { presenter.user_can_perform_any_action? }
    let(:current_ability) { ability }

    context 'when user can perform at least 1 action' do
      before do
        expect(current_ability).to receive(:can?).with(:edit, presenter.id).and_return false
        expect(current_ability).to receive(:can?).with(:destroy, presenter.id).and_return false
        expect(current_ability).to receive(:can?).with(:download, presenter.id).and_return true
      end

      it { is_expected.to be true }
    end
    context 'when user cannot perform any action' do
      before do
        expect(current_ability).to receive(:can?).with(:edit, presenter.id).and_return false
        expect(current_ability).to receive(:can?).with(:destroy, presenter.id).and_return false
        expect(current_ability).to receive(:can?).with(:download, presenter.id).and_return false
      end

      it { is_expected.to be false }
    end
  end

  describe "properties delegated to solr_document" do
    let(:solr_properties) do
      ["date_uploaded", "title_or_label",
       "contributor", "creator", "title", "description", "publisher",
       "subject", "language", "license", "format_label", "file_size",
       "height", "width", "filename", "well_formed", "page_count",
       "file_title", "last_modified", "original_checksum", "mime_type",
       "duration", "sample_rate"]
    end

    it "delegates to the solr_document" do
      solr_properties.each do |property|
        expect(solr_document).to receive(property.to_sym)
        presenter.send(property)
      end
    end
    it { is_expected.to delegate_method(:depositor).to(:solr_document) }
    it { is_expected.to delegate_method(:keyword).to(:solr_document) }
    it { is_expected.to delegate_method(:date_created).to(:solr_document) }
    it { is_expected.to delegate_method(:date_modified).to(:solr_document) }
    it { is_expected.to delegate_method(:itemtype).to(:solr_document) }
    it { is_expected.to delegate_method(:fetch).to(:solr_document) }
    it { is_expected.to delegate_method(:first).to(:solr_document) }
    it { is_expected.to delegate_method(:has?).to(:solr_document) }
  end

  describe '#link_name' do
    context "with a user who can view the file" do
      before do
        allow(ability).to receive(:can?).with(:read, "123abc").and_return(true)
      end
      it "shows the title" do
        expect(presenter.link_name).to eq 'File title'
        expect(presenter.link_name).not_to eq 'filename.tif'
      end
    end

    context "with a user who cannot view the file" do
      before do
        allow(ability).to receive(:can?).with(:read, "123abc").and_return(false)
      end
      it "hides the title" do
        expect(presenter.link_name).to eq 'File'
      end
    end
  end

  describe '#tweeter' do
    subject { presenter.tweeter }

    it 'delegates the depositor as the user_key to TwitterPresenter.call' do
      expect(Hyrax::TwitterPresenter).to receive(:twitter_handle_for).with(user_key: solr_document.depositor)
      subject
    end
  end

  describe "#event_class" do
    subject { presenter.event_class }

    it { is_expected.to eq 'FileSet' }
  end

  describe '#events' do
    subject(:events) { presenter.events }

    let(:event_stream) { double }
    let(:response) { double }

    before do
      allow(presenter).to receive(:event_stream).and_return(event_stream)
    end

    it 'calls the event store' do
      allow(event_stream).to receive(:fetch).with(100).and_return(response)
      expect(events).to eq response
    end
  end

  describe '#event_stream' do
    let(:object_stream) { double }

    it 'returns a Nest stream' do
      expect(Hyrax::RedisEventStore).to receive(:for).with(Nest).and_return(object_stream)
      presenter.send(:event_stream)
    end
  end

  describe "characterization" do
    let(:user) { double(user_key: 'user') }

    describe "#characterization_metadata" do
      subject { presenter.characterization_metadata }

      it "only has set attributes are in the metadata" do
        expect(subject[:height]).to be_blank
        expect(subject[:page_count]).to be_blank
      end

      context "when height is set" do
        let(:attributes) { { height_is: '444' } }

        it "only has set attributes are in the metadata" do
          expect(subject[:height]).not_to be_blank
          expect(subject[:page_count]).to be_blank
        end
      end
    end

    describe "#characterized?" do
      subject { presenter }

      it { is_expected.not_to be_characterized }

      context "when height is set" do
        let(:attributes) { { height_is: '444' } }

        it { is_expected.to be_characterized }
      end

      context "when file_format is set" do
        let(:attributes) { { file_format_tesim: ['format'] } }

        it { is_expected.to be_characterized }
      end
    end

    describe "#label_for_term" do
      subject { presenter.label_for_term(:titleized_key) }

      it { is_expected.to eq("Titleized Key") }
    end

    describe "with additional characterization metadata" do
      let(:additional_metadata) do
        {
          foo: ["bar"],
          fud: ["bars", "cars"]
        }
      end

      before { allow(presenter).to receive(:additional_characterization_metadata).and_return(additional_metadata) }
      subject { presenter }

      specify do
        expect(subject).to be_characterized
        expect(subject.characterization_metadata[:foo]).to contain_exactly("bar")
        expect(subject.characterization_metadata[:fud]).to contain_exactly("bars", "cars")
      end
    end

    describe "characterization values" do
      before { allow(presenter).to receive(:characterization_metadata).and_return(mock_metadata) }

      context "with a limited set of short values" do
        let(:mock_metadata) { { term: ["asdf", "qwer"] } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("asdf", "qwer") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to be_empty }
        end
      end

      context "with a value set exceeding the configured amount" do
        let(:mock_metadata) { { term: ["1", "2", "3", "4", "5", "6", "7", "8"] } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("1", "2", "3", "4", "5") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to contain_exactly("6", "7", "8") }
        end
      end

      context "with values exceeding 250 characters" do
        let(:mock_metadata) { { term: [("a" * 251), "2", "3", "4", "5", "6", ("b" * 251)] } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly(("a" * 247) + "...", "2", "3", "4", "5") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to contain_exactly("6", (("b" * 247) + "...")) }
        end
      end

      context "with a string as a value" do
        let(:mock_metadata) { { term: "string" } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("string") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to be_empty }
        end
      end

      context "with an integer as a value" do
        let(:mock_metadata) { { term: 1440 } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("1440") }
        end
      end
    end
  end

  describe 'IIIF integration' do
    let(:file_set) { create(:file_set) }
    let(:solr_document) { SolrDocument.new(file_set.to_solr) }
    let(:request) { double(base_url: 'http://test.host') }
    let(:presenter) { described_class.new(solr_document, ability, request) }
    let(:id) { CGI.escape(file_set.original_file.id) }
    let(:read_permission) { true }

    before do
      allow(ability).to receive(:can?).with(:read, solr_document.id).and_return(read_permission)
    end

    describe "#display_image" do
      subject { presenter.display_image }

      context 'without a file' do
        let(:id) { 'bogus' }

        it { is_expected.to be_nil }
      end

      context 'with a file' do
        before do
          Hydra::Works::AddFileToFileSet.call(file_set,
                                              file_path, :original_file)
        end

        context "when the file is not an image" do
          let(:file_path) { File.open(fixture_path + '/hyrax_generic_stub.txt') }

          it { is_expected.to be_nil }
        end

        context "when the file is an image" do
          let(:file_path) { File.open(fixture_path + '/world.png') }

          before do
            allow(solr_document).to receive(:image?).and_return(true)
          end

          it { is_expected.to be_instance_of IIIFManifest::DisplayImage }
          its(:url) { is_expected.to eq "http://test.host/images/#{id}/full/600,/0/default.jpg" }

          context 'with custom image size default' do
            let(:custom_image_size) { '666,' }

            around do |example|
              default_image_size = Hyrax.config.iiif_image_size_default
              Hyrax.config.iiif_image_size_default = custom_image_size
              example.run
              Hyrax.config.iiif_image_size_default = default_image_size
            end

            it { is_expected.to be_instance_of IIIFManifest::DisplayImage }
            its(:url) { is_expected.to eq "http://test.host/images/#{id}/full/#{custom_image_size}/0/default.jpg" }
          end

          context 'with custom image url builder' do
            let(:id) { file_set.original_file.id }
            let(:custom_builder) do
              ->(file_id, base_url, _size) { "#{base_url}/downloads/#{file_id.split('/').first}" }
            end

            around do |example|
              default_builder = Hyrax.config.iiif_image_url_builder
              Hyrax.config.iiif_image_url_builder = custom_builder
              example.run
              Hyrax.config.iiif_image_url_builder = default_builder
            end

            it { is_expected.to be_instance_of IIIFManifest::DisplayImage }
            its(:url) { is_expected.to eq "http://test.host/downloads/#{id.split('/').first}" }
          end

          context "when the user doesn't have permission to view the image" do
            let(:read_permission) { false }

            it { is_expected.to be_nil }
          end
        end
      end
    end

    describe "#iiif_endpoint" do
      subject { presenter.send(:iiif_endpoint, file_set.original_file.id) }

      before do
        allow(Hyrax.config).to receive(:iiif_image_server?).and_return(riiif_enabled)
        Hydra::Works::AddFileToFileSet.call(file_set,
                                            File.open(fixture_path + '/world.png'), :original_file)
      end

      context 'with iiif_image_server enabled' do
        let(:riiif_enabled) { true }

        its(:url) { is_expected.to eq "http://test.host/images/#{id}" }
        its(:profile) { is_expected.to eq 'http://iiif.io/api/image/2/level2.json' }

        context 'with a custom iiif image profile' do
          let(:custom_profile) { 'http://iiif.io/api/image/2/level1.json' }

          around do |example|
            default_profile = Hyrax.config.iiif_image_compliance_level_uri
            Hyrax.config.iiif_image_compliance_level_uri = custom_profile
            example.run
            Hyrax.config.iiif_image_compliance_level_uri = default_profile
          end

          its(:profile) { is_expected.to eq custom_profile }
        end
      end

      context 'with iiif_image_server disabled' do
        let(:riiif_enabled) { false }

        it { is_expected.to be nil }
      end
    end
  end
end
