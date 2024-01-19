# frozen_string_literal: true
require 'iiif_manifest'

RSpec.describe Hyrax::FileSetPresenter do
  subject(:presenter) { described_class.new(solr_document, ability) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:ability) { Ability.new(user) }
  let(:attributes) { Hyrax::ValkyrieIndexer.for(resource: file_set).to_solr }
  let(:user) { FactoryBot.create(:admin) }

  let(:file_set) do
    FactoryBot.valkyrie_create(:hyrax_file_set,
                               depositor: user.user_key,
                               edit_users: [user],
                               label: "filename.tif",
                               title: ["File title"])
  end

  describe 'stats_path' do
    its(:stats_path) { is_expected.to eq Hyrax::Engine.routes.url_helpers.stats_file_path(id: file_set, locale: 'en') }
  end

  describe "#to_s" do
    its(:to_s) { is_expected.to eq 'File title' }
  end

  describe "#human_readable_type" do
    its(:human_readable_type) { is_expected.to eq 'File Set' }
  end

  describe "#model_name" do
    its(:model_name) { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe "#to_partial_path" do
    its(:to_partial_path) { is_expected.to eq 'hyrax/file_sets/file_set' }
  end

  describe "office_document?" do
    it { is_expected.not_to be_office_document }
  end

  describe "#user_can_perform_any_action?" do
    let(:current_ability) { ability }

    it 'is deprecated' do
      expect(Deprecation).to receive(:warn).at_least(:once)

      presenter.user_can_perform_any_action?
    end

    context 'when user can perform at least 1 action' do
      before do
        expect(ability).to receive(:can?).with(:edit, presenter.id).and_return false
        expect(ability).to receive(:can?).with(:destroy, presenter.id).and_return false
        expect(ability).to receive(:can?).with(:download, presenter.id).and_return true
      end

      its(:user_can_perform_any_action?) { is_expected.to eq true }
    end

    context 'when user cannot perform any action' do
      before do
        expect(ability).to receive(:can?).with(:edit, presenter.id).and_return false
        expect(ability).to receive(:can?).with(:destroy, presenter.id).and_return false
        expect(ability).to receive(:can?).with(:download, presenter.id).and_return false
      end

      its(:user_can_perform_any_action?) { is_expected.to eq false }
    end
  end

  describe "properties delegated to solr_document" do
    let(:solr_properties) do
      ["date_uploaded", "title_or_label",
       "contributor", "creator", "title", "description", "publisher",
       "subject", "language", "license", "format_label", "file_size",
       "height", "width", "filename", "well_formed", "page_count",
       "file_title", "last_modified", "original_checksum", "mime_type",
       "duration", "sample_rate", "alpha_channels", "original_file_id"]
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
      let(:file_set) do
        FactoryBot.valkyrie_create(:hyrax_file_set,
                                   read_users: [user],
                                   label: "filename.tif",
                                   title: ["File title"])
      end

      it "shows the title" do
        expect(presenter.link_name).to eq 'File title'
        expect(presenter.link_name).not_to eq 'filename.tif'
      end
    end

    context "with a user who cannot view the file" do
      let(:ability) { Ability.new(other_user) }
      let(:other_user) { FactoryBot.create(:user) }

      it "hides the title" do
        expect(presenter.link_name).to eq 'File'
      end
    end
  end

  describe '#tweeter' do
    it 'delegates the depositor as the user_key to TwitterPresenter.call' do
      expect(Hyrax::TwitterPresenter)
        .to receive(:twitter_handle_for)
        .with(user_key: solr_document.depositor)
        .and_return(:fake_result)

      expect(presenter.tweeter).to eq :fake_result
    end
  end

  describe "#event_class" do
    its(:event_class) { is_expected.to eq 'FileSet' }
  end

  describe '#events' do
    subject(:events) { presenter.events }

    let(:event_stream) { double('event stream') }
    let(:response) { double('response') }

    before do
      allow(presenter).to receive(:event_stream).and_return(event_stream)
    end

    it 'calls the event store' do
      allow(event_stream).to receive(:fetch).with(100).and_return(response)
      expect(events).to eq response
    end
  end

  describe '#event_stream' do
    let(:object_stream) { double('object_stream') }

    it 'returns a Nest stream' do
      expect(Hyrax::RedisEventStore).to receive(:for).with(Nest).and_return(object_stream)
      presenter.send(:event_stream)
    end
  end

  describe "characterization" do
    describe "#characterization_metadata" do
      it "only has set attributes are in the metadata" do
        expect(presenter.characterization_metadata).not_to have_key(:height)
        expect(presenter.characterization_metadata).not_to have_key(:page_count)
      end

      context "when height is set" do
        let(:attributes) { { height_is: '444' } }

        it "has set attributes are in the metadata" do
          expect(presenter.characterization_metadata[:height]).to eq '444'
          expect(presenter.characterization_metadata).not_to have_key(:page_count)
        end
      end
    end

    describe "#characterized?" do
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
      it "titleizes the input" do
        expect(presenter.label_for_term(:titleized_key)).to eq("Titleized Key")
      end
    end

    describe "with additional characterization metadata" do
      let(:additional_metadata) do
        {
          foo: ["bar"],
          fud: ["bars", "cars"]
        }
      end

      # this is a little absurd, but it's not clear to me what the interface is supposed to be
      # how do i actually inject additional metadata?
      before { allow(presenter).to receive(:additional_characterization_metadata).and_return(additional_metadata) } # rubocop:disable RSpec/SubjectStub

      it "adds the metadata" do
        expect(presenter).to be_characterized
        expect(subject.characterization_metadata[:foo]).to contain_exactly("bar")
        expect(subject.characterization_metadata[:fud]).to contain_exactly("bars", "cars")
      end
    end

    describe "characterization values" do
      before { allow(presenter).to receive(:characterization_metadata).and_return(mock_metadata) } # rubocop:disable RSpec/SubjectStub

      context "with a limited set of short values" do
        let(:mock_metadata) { { term: ["asdf", "qwer"] } }

        describe "#primary_characterization_values" do
          it "includes the characterization metadata" do
            expect(presenter.primary_characterization_values(:term))
              .to contain_exactly("asdf", "qwer")
          end
        end

        describe "#secondary_characterization_values" do
          it("is empty") { expect(presenter.secondary_characterization_values(:term)).to be_empty }
        end
      end

      context "with a value set exceeding the configured amount" do
        let(:mock_metadata) { { term: ["1", "2", "3", "4", "5", "6", "7", "8"] } }

        describe "#primary_characterization_values" do
          it "contains the configured number of values" do
            expect(presenter.primary_characterization_values(:term))
              .to contain_exactly("1", "2", "3", "4", "5")
          end
        end

        describe "#secondary_characterization_values" do
          it "includes the excess" do
            expect(presenter.secondary_characterization_values(:term))
              .to contain_exactly("6", "7", "8")
          end
        end
      end

      context "with values exceeding 250 characters" do
        let(:mock_metadata) { { term: [("a" * 251), "2", "3", "4", "5", "6", ("b" * 251)] } }

        describe "#primary_characterization_values" do
          it "truncates" do
            expect(presenter.primary_characterization_values(:term))
              .to contain_exactly(("a" * 247) + "...", "2", "3", "4", "5")
          end
        end

        describe "#secondary_characterization_values" do
          it "truncates" do
            expect(presenter.secondary_characterization_values(:term))
              .to contain_exactly("6", (("b" * 247) + "..."))
          end
        end
      end

      context "with a string as a value" do
        let(:mock_metadata) { { term: "string" } }

        describe "#primary_characterization_values" do
          it "contains the string value" do
            expect(presenter.primary_characterization_values(:term))
              .to contain_exactly("string")
          end
        end

        describe "#secondary_characterization_values" do
          it("is empty") { expect(presenter.secondary_characterization_values(:term)).to be_empty }
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
    def uri_segment_escape(uri)
      ActionDispatch::Journey::Router::Utils.escape_segment(uri)
    end

    subject(:presenter) { described_class.new(solr_document, ability, request) }

    let(:file) { FactoryBot.create(:uploaded_file) }
    let(:file_metadata) { FactoryBot.valkyrie_create(:file_metadata, :original_file, :with_file, file: file) }
    let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
    let(:request) { double('request', base_url: 'http://test.host') }
    let(:id) { "#{file_set.id}/files/#{file_metadata.id}/#{Digest::MD5.hexdigest(file_metadata.file.version_id)}" }

    describe "#display_image" do
      context 'without a file' do
        let(:id) { 'bogus' }

        its(:display_image) { is_expected.to be_nil }
      end

      context 'with a file' do
        let(:file_set) do
          FactoryBot.valkyrie_create(:hyrax_file_set,
                                     files: [file_metadata],
                                     original_file: file_metadata)
        end

        context "when the file is not an image" do
          let(:file) { FactoryBot.create(:uploaded_file, :audio) }

          its(:display_image) { is_expected.to be_nil }
        end

        context "when the file is an image" do
          its(:display_image) { is_expected.to be_instance_of IIIFManifest::DisplayImage }
          its(:display_image) { is_expected.to have_attributes(url: "http://test.host/images/#{uri_segment_escape(id)}/full/600,/0/default.jpg") }

          context 'with custom image size default' do
            let(:custom_image_size) { '666,' }

            around do |example|
              default_image_size = Hyrax.config.iiif_image_size_default
              Hyrax.config.iiif_image_size_default = custom_image_size
              example.run
              Hyrax.config.iiif_image_size_default = default_image_size
            end

            its(:display_image) { is_expected.to be_instance_of IIIFManifest::DisplayImage }
            its(:display_image) { is_expected.to have_attributes(url: "http://test.host/images/#{uri_segment_escape(id)}/full/#{custom_image_size}/0/default.jpg") }
          end

          context 'with custom image url builder' do
            let(:id) { file_set.id.to_s }
            let(:custom_builder) do
              ->(file_id, base_url, _size, _format) { "#{base_url}/downloads/#{file_id.split('/').first}" }
            end

            around do |example|
              default_builder = Hyrax.config.iiif_image_url_builder
              Hyrax.config.iiif_image_url_builder = custom_builder
              example.run
              Hyrax.config.iiif_image_url_builder = default_builder
            end

            its(:display_image) { is_expected.to be_instance_of IIIFManifest::DisplayImage }
            its(:display_image) { is_expected.to have_attributes(url: "http://test.host/downloads/#{id.split('/').first}") }
          end

          context "when the user doesn't have permission to view the image" do
            let(:ability) { Ability.new(other_user) }
            let(:other_user) { FactoryBot.create(:user) }

            its(:display_image) { is_expected.to be_nil }
          end
        end
      end
    end

    describe "#iiif_endpoint" do
      subject { presenter.send(:iiif_endpoint, id) }

      before do
        allow(Hyrax.config).to receive(:iiif_image_server?).and_return(riiif_enabled)
      end

      context 'with iiif_image_server enabled' do
        let(:riiif_enabled) { true }

        its(:url) { is_expected.to eq "http://test.host/images/#{uri_segment_escape(id)}" }
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

  describe "#parent" do
    let(:read_permission) { true }
    let(:edit_permission) { false }

    let(:active) do
      ::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#active')
    end

    let(:inactive) do
      ::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#inactive')
    end

    let(:file_set) do
      FactoryBot.valkyrie_create(:hyrax_file_set, read_groups: ['public'])
    end

    let(:file_set_inactive) do
      FactoryBot.valkyrie_create(:hyrax_file_set, read_groups: ['public'])
    end

    describe "active parent" do
      let(:read_permission) { true }
      let(:edit_permission) { false }
      let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: file_set).to_solr) }
      let(:solr_document_work) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: parent).to_solr) }
      let(:request) { double(base_url: 'http://test.host') }
      let(:presenter) { described_class.new(solr_document, ability, request) }

      let!(:parent) do
        FactoryBot.valkyrie_create(:hyrax_work, :public, state: active, member_ids: [file_set.id])
      end

      before do
        allow(ability).to receive(:can?).with(:read, anything) do |_read, solr_doc|
          solr_document_work.id == solr_doc.id && read_permission
        end

        allow(ability).to receive(:can?).with(:edit, anything) do |_read, solr_doc|
          solr_document_work.id == solr_doc.id && edit_permission
        end
      end

      context "is created when parent work is active" do
        its(:parent) { is_expected.not_to be_nil }
      end
    end

    describe "inactive parent" do
      let(:read_permission) { true }
      let(:edit_permission) { false }
      let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: file_set).to_solr) }
      let(:solr_document_work) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: parent).to_solr) }
      let(:request) { double(base_url: 'http://test.host') }
      let(:presenter) { described_class.new(solr_document, ability, request) }

      let!(:parent) do
        FactoryBot.valkyrie_create(:hyrax_work, :public, state: inactive, member_ids: [file_set.id])
      end

      before do
        allow(ability).to receive(:can?).with(:read, anything) do |_read, solr_doc|
          solr_document_work.id == solr_doc.id && read_permission
        end

        allow(ability).to receive(:can?).with(:edit, anything) do |_read, solr_doc|
          solr_document_work.id == solr_doc.id && edit_permission
        end
      end

      context "is created when parent work is active" do
        it "raises an error" do
          expect { presenter.parent }.to raise_error(Hyrax::WorkflowAuthorizationException)
        end
      end
    end
  end
end
