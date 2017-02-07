describe Hyrax::WorkShowPresenter do
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:request) { double }

  let(:attributes) do
    { "id" => '888888',
      "title_tesim" => ['foo', 'bar'],
      "human_readable_type_tesim" => ["Generic Work"],
      "has_model_ssim" => ["GenericWork"],
      "date_created_tesim" => ['an unformatted date'] }
  end
  let(:ability) { nil }
  let(:presenter) { described_class.new(solr_document, ability, request) }

  subject { described_class.new(double, double) }
  it { is_expected.to delegate_method(:to_s).to(:solr_document) }
  it { is_expected.to delegate_method(:human_readable_type).to(:solr_document) }
  it { is_expected.to delegate_method(:date_created).to(:solr_document) }
  it { is_expected.to delegate_method(:date_modified).to(:solr_document) }
  it { is_expected.to delegate_method(:date_uploaded).to(:solr_document) }

  it { is_expected.to delegate_method(:based_near).to(:solr_document) }
  it { is_expected.to delegate_method(:related_url).to(:solr_document) }
  it { is_expected.to delegate_method(:depositor).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:keyword).to(:solr_document) }
  it { is_expected.to delegate_method(:itemtype).to(:solr_document) }

  describe "#model_name" do
    subject { presenter.model_name }
    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe '#stats_path' do
    let(:user) { 'sarah' }
    let(:ability) { double "Ability" }
    let(:work) { build(:generic_work, id: '123abc') }
    let(:attributes) { work.to_solr }
    it { expect(presenter.stats_path).to eq Hyrax::Engine.routes.url_helpers.stats_work_path(id: work) }
  end

  describe '#itemtype' do
    let(:work) { build(:generic_work, resource_type: type) }
    let(:attributes) { work.to_solr }
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
  end

  describe 'admin users' do
    let(:user)    { create(:user) }
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
      subject { presenter.editor? }
      it { is_expected.to be true }
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
    let(:obj) { create(:work_with_file_and_work) }
    let(:attributes) { obj.to_solr }

    it "filters out members that are file sets" do
      expect(presenter.work_presenters.size).to eq 1
      expect(presenter.work_presenters.first).to be_instance_of(described_class)
    end
  end

  describe "#member_presenters" do
    let(:obj) { create(:work_with_file_and_work) }
    let(:attributes) { obj.to_solr }

    it "returns appropriate classes for each" do
      expect(presenter.member_presenters.size).to eq 2
      expect(presenter.member_presenters.first).to be_instance_of(Hyrax::FileSetPresenter)
      expect(presenter.member_presenters.last).to be_instance_of(described_class)
    end
  end

  describe "#file_set_presenters" do
    let(:obj) { create(:work_with_ordered_files) }
    let(:attributes) { obj.to_solr }

    it "displays them in order" do
      expect(presenter.file_set_presenters.map(&:id)).to eq obj.ordered_member_ids
    end

    context "solr query" do
      before do
        expect(ActiveFedora::SolrService).to receive(:query).twice.with(anything, hash_including(rows: 10_000)).and_return([])
      end

      it "requests >10 rows" do
        presenter.file_set_presenters
      end
    end

    context "when some of the members are not file sets" do
      let(:another_work) { create(:work) }
      before do
        obj.ordered_members << another_work
        obj.save!
      end

      it "filters out members that are not file sets" do
        expect(presenter.file_set_presenters.map(&:id)).not_to include another_work.id
      end
    end
  end

  describe "#representative_presenter" do
    let(:obj) { create(:work_with_representative_file) }
    let(:attributes) { obj.to_solr }
    it "has a representative" do
      expect(Hyrax::PresenterFactory).to receive(:build_presenters)
        .with([obj.members[0].id], Hyrax::CompositePresenterFactory, ability, request).and_return ["abc"]
      expect(presenter.representative_presenter).to eq("abc")
    end
  end

  describe '#page_title' do
    subject { presenter.page_title }
    it { is_expected.to eq 'foo' }
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
        expect(Rails.logger).to receive(:warn).with('Hyrax::WorkShowPresenter attempted to render restrictions, but no method exists with that name.')
        presenter.attribute_to_html(:restrictions)
      end
    end
  end

  context "with workflow" do
    let(:user) { create(:user) }
    let(:ability) { Ability.new(user) }
    let(:entity) { instance_double(Sipity::Entity) }
    describe "#workflow" do
      subject { presenter.workflow }
      it { is_expected.to be_kind_of Hyrax::WorkflowPresenter }
    end
  end

  context "with inspect_work" do
    let(:user) { create(:user) }
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
      subject { presenter.export_as_jsonld }
      it do
        is_expected.to eq '{
  "@context": {
    "dc": "http://purl.org/dc/terms/"
  },
  "@id": "http://example.com/1",
  "dc:title": "Test title"
}'
      end
    end
  end
end
