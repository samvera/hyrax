# frozen_string_literal: true
RSpec.describe Hyrax::WorkShowPresenter do
  subject(:presenter) { described_class.new(solr_document, ability, request) }
  let(:ability) { double Ability }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:request) { double(host: 'example.org', base_url: 'http://example.org') }
  let(:user_key) { 'a_user_key' }
  let(:representative_id) { nil }

  let(:attributes) do
    { "id" => '888888',
      "title_tesim" => ['foo', 'bar'],
      "human_readable_type_tesim" => ["Generic Work"],
      "has_model_ssim" => ["GenericWork"],
      "date_created_tesim" => ['an unformatted date'],
      "depositor_tesim" => user_key,
      "hasRelatedMediaFragment_ssim" => representative_id }
  end

  it { is_expected.to delegate_method(:to_s).to(:solr_document) }

  it { is_expected.to respond_to(:suppressed?) }
  it { is_expected.to respond_to(:human_readable_type) }
  it { is_expected.to respond_to(:date_created) }
  it { is_expected.to respond_to(:date_modified) }
  it { is_expected.to respond_to(:date_uploaded) }
  it { is_expected.to respond_to(:rights_statement) }
  it { is_expected.to respond_to(:rights_notes) }

  it { is_expected.to respond_to(:based_near_label) }
  it { is_expected.to respond_to(:related_url) }
  it { is_expected.to respond_to(:depositor) }
  it { is_expected.to respond_to(:identifier) }
  it { is_expected.to respond_to(:resource_type) }
  it { is_expected.to respond_to(:keyword) }
  it { is_expected.to respond_to(:itemtype) }
  it { is_expected.to delegate_method(:member_presenters).to(:member_presenter_factory) }
  it { is_expected.to delegate_method(:ordered_ids).to(:member_presenter_factory) }

  describe "#model_name" do
    subject { presenter.model_name }

    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe '#manifest_url' do
    subject { presenter.manifest_url }

    it { is_expected.to eq 'http://example.org/concern/generic_works/888888/manifest' }
  end

  describe '#iiif_viewer?' do
    let(:image_boolean) { false }
    let(:iiif_enabled) { true }
    let(:file_set_presenter) { double(Hyrax::FileSetPresenter, id: '888888', image?: true) }
    let(:file_set_presenters) { [file_set_presenter] }
    let(:member_presenter_factory) { instance_double(Hyrax::MemberPresenterFactory) }
    let(:read_permission) { true }
    let(:representative_present) { false }

    let(:representative_presenter) do
      double('representative', present?: representative_present, image?: image_boolean)
    end

    before do
      presenter.member_presenter_factory = member_presenter_factory

      allow(member_presenter_factory)
        .to receive(:member_presenters)
        .with(['representative-123'])
        .and_return([representative_presenter])

      allow(member_presenter_factory)
        .to receive(:file_set_presenters)
        .and_return(file_set_presenters)

      allow(ability).to receive(:can?).with(:read, solr_document.id).and_return(read_permission)
      allow(Hyrax.config).to receive(:iiif_image_server?).and_return(iiif_enabled)
    end

    subject { presenter.iiif_viewer? }

    context 'with no representative_id' do
      let(:representative_id) { nil }

      it { is_expected.to be false }
    end

    context 'with no representative_presenter' do
      let(:representative_id) { 'representative-123' }

      it { is_expected.to be false }
    end

    context 'with non-image representative_presenter' do
      let(:representative_id) { 'representative-123' }
      let(:representative_present) { true }
      let(:image_boolean) { false }

      it { is_expected.to be false }
    end

    context 'with IIIF image server turned off' do
      let(:representative_id) { 'representative-123' }
      let(:representative_present) { true }
      let(:image_boolean) { true }
      let(:iiif_enabled) { false }

      it { is_expected.to be false }
    end

    context 'with representative image and IIIF turned on' do
      let(:representative_id) { 'representative-123' }
      let(:representative_present) { true }
      let(:image_boolean) { true }
      let(:iiif_enabled) { true }

      it { is_expected.to be true }

      context "when the user doesn't have permission to view the image" do
        let(:read_permission) { false }

        it { is_expected.to be false }
      end
    end
  end

  describe '#stats_path' do
    let(:user) { 'sarah' }
    let(:ability) { double "Ability" }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: work).to_solr) }

    it { expect(presenter.stats_path).to eq Hyrax::Engine.routes.url_helpers.stats_work_path(id: work, locale: 'en') }
  end

  describe '#itemtype' do
    let(:work) { FactoryBot.valkyrie_create(:monograph, resource_type: type) }
    let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: work).to_solr) }
    let(:ability) { double "Ability" }

    subject { presenter.itemtype }

    context 'when resource_type is Audio' do
      let(:type) { ['Audio'] }

      it do
        is_expected.to eq 'http://schema.org/AudioObject'
      end
    end

    context 'when resource_type is Conference Proceeding' do
      let(:type) { ['Conference Proceeding'] }

      it { is_expected.to eq 'http://schema.org/ScholarlyArticle' }
    end

    context 'when resource_type is not indexed' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

      it do
        is_expected.to eq 'http://schema.org/CreativeWork'
      end
    end
  end

  describe 'admin users' do
    let(:user)    { FactoryBot.create(:user) }
    let(:ability) { Ability.new(user) }
    let(:attributes) do
      {
        "read_access_group_ssim" => ["public"],
        'id' => '99999'
      }
    end

    before { allow(user).to receive_messages(groups: ['admin', 'registered']) }

    context 'with a new public work' do
      it 'can feature the work' do
        allow(user).to receive(:can?).with(:create, FeaturedWork).and_return(true)
        expect(presenter.work_featurable?).to be true
        expect(presenter.display_feature_link?).to be true
        expect(presenter.display_unfeature_link?).to be false
      end
    end

    context 'with a featured work' do
      before { FeaturedWork.create(work_id: attributes.fetch('id')) }
      it 'can unfeature the work' do
        expect(presenter.work_featurable?).to be true
        expect(presenter.display_feature_link?).to be false
        expect(presenter.display_unfeature_link?).to be true
      end
    end

    describe "#editor?" do
      it { is_expected.to be_editor }
    end
  end

  describe '#tweeter' do
    let(:user) { instance_double(User, user_key: 'user_key') }

    subject { presenter.tweeter }

    it 'delegates the depositor as the user_key to TwitterPresenter.twitter_handle_for' do
      expect(Hyrax::TwitterPresenter).to receive(:twitter_handle_for).with(user_key: user_key)
      subject
    end
  end

  describe "#permission_badge" do
    let(:badge) { instance_double(Hyrax::PermissionBadge) }

    before do
      allow(Hyrax::PermissionBadge).to receive(:new).and_return(badge)
    end
    it "calls the PermissionBadge object" do
      expect(badge).to receive(:render)
      presenter.permission_badge
    end
  end

  describe "#work_presenters" do
    let(:obj) { FactoryBot.valkyrie_create(:hyrax_work, :with_file_and_work) }
    let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: obj).to_solr) }

    it "filters out members that are file sets" do
      expect(presenter.work_presenters.count).to eq 1
      expect(presenter.work_presenters.first).to be_instance_of(described_class)
    end
  end

  describe "#member_count" do
    let(:obj) { FactoryBot.valkyrie_create(:hyrax_work, :with_file_and_work) }
    let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: obj).to_solr) }

    it "returns the member count" do
      expect(presenter.member_count).to eq 2
    end

    context "with empty members" do
      let(:obj) { FactoryBot.valkyrie_create(:hyrax_work) }

      it "returns 0" do
        expect(presenter.member_count).to eq 0
      end
    end
  end

  describe "#member_presenters" do
    let(:obj) { FactoryBot.valkyrie_create(:hyrax_work, :with_file_and_work) }
    let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: obj).to_solr) }

    it "returns appropriate classes for each" do
      expect(presenter.member_presenters.count).to eq 2
      expect(presenter.member_presenters.first).to be_instance_of(Hyrax::FileSetPresenter)
      expect(presenter.member_presenters.last).to be_instance_of(described_class)
    end
  end

  describe "#list_of_item_ids_to_display" do
    let(:subject) { presenter.list_of_item_ids_to_display }
    let(:items_list) { (0..9).map { |i| "item#{i}" } }
    let(:request) { double(host: 'example.org', base_url: 'http://example.org', params: { rows: rows, page: page }) }
    let(:rows) { 10 }
    let(:page) { 1 }
    let(:ability) { double "Ability" }
    let(:current_ability) { ability }

    let(:member_presenter_factory) { instance_double(Hyrax::MemberPresenterFactory, ordered_ids: items_list) }

    before do
      presenter.member_presenter_factory = member_presenter_factory

      allow(current_ability).to receive(:can?).with(:read, 'item0').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item1').and_return false
      allow(current_ability).to receive(:can?).with(:read, 'item2').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item3').and_return false
      allow(current_ability).to receive(:can?).with(:read, 'item4').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item5').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item6').and_return false
      allow(current_ability).to receive(:can?).with(:read, 'item7').and_return true
      allow(current_ability).to receive(:can?).with(:read, 'item8').and_return false
      allow(current_ability).to receive(:can?).with(:read, 'item9').and_return true
    end

    context 'when hiding private items' do
      before { allow(Flipflop).to receive(:hide_private_items?).and_return(true) }

      it "returns viewable items" do
        expect(subject.size).to eq 6
        expect(subject).to be_instance_of(Kaminari::PaginatableArray)
        expect(subject).to include("item0", "item2", "item4", "item5", "item7", "item9")
      end
    end

    context 'when including private items' do
      before { allow(Flipflop).to receive(:hide_private_items?).and_return(false) }

      it "returns appropriate items" do
        expect(subject.size).to eq 10
        expect(subject).to be_instance_of(Kaminari::PaginatableArray)
        expect(subject).to eq(items_list)
      end
    end

    context 'with pagination' do
      let(:rows) { 3 }
      let(:page) { 2 }

      before { allow(Flipflop).to receive(:hide_private_items?).and_return(true) }

      it 'partitions the item list and excluding hidden items' do
        expect(subject).to eq(['item5', 'item7', 'item9'])
      end
    end
  end

  describe "#total_pages" do
    let(:items) { 17 }
    let(:items_list) { (0..16).map { |i| "item#{i}" } }
    let(:member_presenter_factory) { instance_double(Hyrax::MemberPresenterFactory, ordered_ids: items_list) }
    let(:request) { double(host: 'example.org', base_url: 'http://example.org', params: { rows: rows }) }
    let(:rows) { 4 }

    before do
      presenter.member_presenter_factory = member_presenter_factory
      allow(Flipflop).to receive(:hide_private_items?).and_return(false)
    end

    it 'calculates number of pages from items and rows' do
      expect(presenter.total_pages).to eq(5)
    end
  end

  describe "#file_set_presenters" do
    let(:obj) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_file_sets) }
    let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: obj).to_solr) }

    it "displays them in order" do
      expect(presenter.file_set_presenters.map(&:id)).to eq obj.member_ids
    end

    context "when some of the members are not file sets" do
      let(:obj) { FactoryBot.valkyrie_create(:hyrax_work, :with_file_and_work) }
      let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: obj).to_solr) }

      it "filters out members that are not file sets" do
        expect(presenter.file_set_presenters.count).to eq 1
      end
    end
  end

  describe "#representative_presenter" do
    let(:obj) { FactoryBot.valkyrie_create(:hyrax_work, :with_one_file_set, :with_representative) }
    let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: obj).to_solr) }

    it "has a representative" do
      expect(presenter.representative_presenter.solr_document.id).to eq(obj.member_ids.first.to_s)
    end

    context 'without a representative' do
      let(:obj) { FactoryBot.valkyrie_create(:hyrax_work) }

      it 'has a nil presenter' do
        expect(presenter.representative_presenter).to be_nil
      end
    end

    context 'has an unindexed representative' do
      it 'has a nil presenter' do
        expect(presenter).to receive(:member_presenters)
          .with([obj.member_ids[0]])
          .and_raise Hyrax::ObjectNotFoundError
        expect(presenter.representative_presenter).to be_nil
      end
    end

    context 'when it is its own representative' do
      let(:obj) { FactoryBot.valkyrie_create(:hyrax_work) }

      before do
        obj.representative_id = obj.id
        Hyrax.persister.save(resource: obj)
      end

      it 'has a nil presenter; avoids infinite loop' do
        expect(presenter.representative_presenter).to be_nil
      end
    end
  end

  describe "#download_url" do
    subject { presenter.download_url }

    let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: work).to_solr) }

    context "with a representative" do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_one_file_set, :with_representative) }

      it { is_expected.to eq "http://#{request.host}/downloads/#{work.representative_id}" }
    end

    context "without a representative" do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

      it { is_expected.to eq '' }
    end
  end

  describe '#page_title' do
    subject { presenter.page_title }

    it { is_expected.to eq "Generic Work | foo | ID: 888888 | #{I18n.t('hyrax.product_name')}" }
  end

  describe "#valid_child_concerns" do
    subject { presenter }

    it "delegates to the class attribute of the model" do
      allow(GenericWork).to receive(:valid_child_concerns).and_return([GenericWork])

      expect(subject.valid_child_concerns).to eq [GenericWork]
    end
  end

  describe "#attribute_to_html" do
    let(:renderer) { double('renderer') }

    context 'with an existing field' do
      before do
        allow(Hyrax::Renderers::AttributeRenderer).to receive(:new)
          .with(:title, ['foo', 'bar'], {})
          .and_return(renderer)
      end

      it "calls the AttributeRenderer" do
        expect(renderer).to receive(:render)
        presenter.attribute_to_html(:title)
      end
    end

    context "with a field that doesn't exist" do
      it "logs a warning" do
        expect(Hyrax.logger).to receive(:warn).with('Hyrax::WorkShowPresenter attempted to render restrictions, but no method exists with that name.')
        presenter.attribute_to_html(:restrictions)
      end
    end
  end

  context "with workflow" do
    let(:user) { FactoryBot.create(:user) }
    let(:ability) { Ability.new(user) }
    let(:entity) { instance_double(Sipity::Entity) }

    describe "#workflow" do
      subject { presenter.workflow }

      it { is_expected.to be_kind_of Hyrax::WorkflowPresenter }
    end
  end

  context "with inspect_work" do
    let(:user) { FactoryBot.create(:user) }
    let(:ability) { Ability.new(user) }

    describe "#inspect_work" do
      subject { presenter.inspect_work }

      it { is_expected.to be_kind_of Hyrax::InspectWorkPresenter }
    end
  end

  describe "graph export methods" do
    let(:graph) do
      RDF::Graph.new.tap do |g|
        g << [RDF::URI('http://example.com/1'), RDF::Vocab::DC.title, 'Test title']
      end
    end

    let(:exporter) { double }

    before do
      allow(Hyrax::GraphExporter).to receive(:new).and_return(exporter)
      allow(exporter).to receive(:fetch).and_return(graph)
    end

    describe "#export_as_nt" do
      subject { presenter.export_as_nt }

      it { is_expected.to eq "<http://example.com/1> <http://purl.org/dc/terms/title> \"Test title\" .\n" }
    end

    describe "#export_as_ttl" do
      subject { presenter.export_as_ttl }

      it { is_expected.to eq "\n<http://example.com/1> <http://purl.org/dc/terms/title> \"Test title\" .\n" }
    end

    describe "#export_as_jsonld" do
      it do
        json = '{"@context": {"dc": "http://purl.org/dc/terms/"},"@id": "http://example.com/1","dc:title": "Test title"}'

        expect(JSON.parse(presenter.export_as_jsonld)).to eq JSON.parse(json)
      end
    end
  end

  describe "#manifest" do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_one_file_set) }
    let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: work).to_solr) }

    describe "#sequence_rendering" do
      subject { presenter.sequence_rendering }
      let(:work) do
        FactoryBot.valkyrie_create(:hyrax_work, uploaded_files: [FactoryBot.create(:uploaded_file)])
      end

      it "returns a hash containing the rendering information" do
        work.rendering_ids = [work.member_ids.first]
        expect(subject).to be_an Array
      end
    end

    describe "#manifest_metadata" do
      subject do
        presenter.manifest_metadata
      end

      before do
        work.title = ['Test title', 'Another test title']
      end

      it "returns an array of metadata values" do
        expect(subject[0]['label']).to eq('Title')
        expect(subject[0]['value']).to include('Test title', 'Another test title')
      end

      context "when there are html tags in the metadata" do
        before do
          work.title = ["The title<img src=xx:x onerror=eval('\x61ler\x74(1)') />", 'Another test title']
        end

        it "sanitizes the metadata values" do
          expect(subject[0]['value']).to include('The title<img>', 'Another test title')
        end
      end
    end
  end

  describe "#grouped_presenters" do
    let(:collections) do
      [FactoryBot.valkyrie_create(:hyrax_collection),
       FactoryBot.valkyrie_create(:hyrax_collection)]
    end

    before do
      allow(presenter)
        .to receive(:member_of_authorized_parent_collections)
        .and_return collections.map(&:id).map(&:to_s)
    end

    it "groups the presenters with the human version of the model name" do
      expect(presenter.grouped_presenters.keys).to contain_exactly("Collection")
    end
  end

  describe "#show_deposit_for?" do
    context "when user has depositable collections" do
      let(:user_collections) { double }

      it "returns true" do
        expect(subject.show_deposit_for?(collections: user_collections)).to be true
      end
    end

    context "when user does not have depositable collections" do
      let(:user_collections) { nil }

      context "and user can create a collection" do
        before do
          allow(ability)
            .to receive(:can?)
            .with(:create_any, Hyrax.config.collection_class)
            .and_return(true)
        end

        it "returns true" do
          expect(subject.show_deposit_for?(collections: user_collections)).to be true
        end
      end

      context "and user can NOT create a collection" do
        before do
          allow(ability)
            .to receive(:can?)
            .with(:create_any, Hyrax.config.collection_class)
            .and_return(false)
        end

        it "returns false" do
          expect(subject.show_deposit_for?(collections: user_collections))
            .to be false
        end
      end
    end
  end

  describe '#iiif_viewer' do
    subject { presenter.iiif_viewer }

    it 'defaults to universal viewer' do
      expect(subject).to be :universal_viewer
    end
  end
end
