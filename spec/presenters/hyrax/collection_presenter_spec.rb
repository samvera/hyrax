# frozen_string_literal: true
RSpec.describe Hyrax::CollectionPresenter do
  subject(:presenter) { described_class.new(solr_doc, ability) }
  let(:collection) do
    build(:hyrax_collection,
          id: 'adc12v',
          title: ['A clever title'])
  end
  let(:ability) { double(::Ability) }
  let(:solr_doc) { SolrDocument.new(solr_hash) }
  let(:solr_hash) { Hyrax::ValkyrieIndexer.for(resource: collection).to_solr }
  let(:collection_type) { create(:collection_type) }

  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:based_near).to(:solr_document) }
  it { is_expected.to delegate_method(:related_url).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
  it { is_expected.to delegate_method(:date_created).to(:solr_document) }

  describe ".terms" do
    # The class method is the default terms only; compound terms are resolved
    # per instance (see "#terms") because a flexible schema is per-resource.
    subject { described_class.terms }

    it 'is the default terms' do
      is_expected.to eq [:total_items, :alternative_title, :size, :resource_type, :creator,
                         :contributor, :keyword, :license, :publisher,
                         :date_created, :subject, :language, :identifier,
                         :based_near, :related_url]
    end
  end

  describe "#terms" do
    it 'starts with the default terms' do
      expect(presenter.terms.first(15)).to eq described_class::DEFAULT_TERMS
    end

    it 'appends this collection\'s inline compound terms' do
      allow(presenter).to receive(:compound_terms).and_return([:participants, :identifiers])
      expect(presenter.terms).to end_with(:participants, :identifiers)
    end
  end

  describe "compound attribute delegation" do
    # Resolution is per instance, from the backing document's compound schema.
    context "when a compound is declared for the collection" do
      before do
        allow(presenter).to receive(:all_compound_names).and_return([:relationships])
        allow(solr_doc).to receive(:relationships).and_return([{ 'related_item' => 'https://example.org' }])
      end

      it "responds to the declared compound reader" do
        expect(presenter).to respond_to(:relationships)
      end

      it "delegates the compound reader to the solr document" do
        expect(presenter.relationships).to eq([{ 'related_item' => 'https://example.org' }])
      end
    end

    context "for an undeclared method" do
      before { allow(presenter).to receive(:all_compound_names).and_return([]) }

      it "does not respond to it" do
        expect(presenter).not_to respond_to(:not_a_compound)
      end

      it "raises NoMethodError" do
        expect { presenter.not_a_compound }.to raise_error(NoMethodError)
      end
    end
  end

  describe "collection type methods" do
    it { is_expected.to delegate_method(:collection_type_is_nestable?).to(:collection_type).as(:nestable?) }
    it { is_expected.to delegate_method(:collection_type_is_brandable?).to(:collection_type).as(:brandable?) }
    it { is_expected.to delegate_method(:collection_type_is_discoverable?).to(:collection_type).as(:discoverable?) }
    it { is_expected.to delegate_method(:collection_type_is_sharable?).to(:collection_type).as(:sharable?) }
    it { is_expected.to delegate_method(:collection_type_is_share_applies_to_new_works?).to(:collection_type).as(:share_applies_to_new_works?) }
    it { is_expected.to delegate_method(:collection_type_is_allow_multiple_membership?).to(:collection_type).as(:allow_multiple_membership?) }
    it { is_expected.to delegate_method(:collection_type_is_require_membership?).to(:collection_type).as(:require_membership?) }
    it { is_expected.to delegate_method(:collection_type_is_assigns_workflow?).to(:collection_type).as(:assigns_workflow?) }
    it { is_expected.to delegate_method(:collection_type_is_assigns_visibility?).to(:collection_type).as(:assigns_visibility?) }

    it "sets a default value on subcollection_counts" do
      expect(subject.subcollection_count).to eq(0)
    end

    it { is_expected.to respond_to(:subcollection_count=).with(1).argument }

    it "provides the amount of subcollections when there are none" do
      subject.subcollection_count = nil
      expect(subject.subcollection_count).to eq(0)
    end

    it "provides the amount of subcollections when they exist" do
      expect(subject.subcollection_count = 5).to eq(5)
    end
  end

  describe('#to_s') { it { expect(presenter.to_s).to eq collection.title.first } }

  describe('#title') { it { is_expected.to have_attributes title: collection.title } }

  describe "#total_items", :clean_repo do
    context "empty collection" do
      let(:ability) { double(::Ability, user_groups: ['public'], current_user: user) }
      let(:user) { create(:user) }
      let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection) }

      before { allow(ability).to receive(:admin?).and_return(false) }

      it 'returns 0' do
        expect(presenter.total_items).to eq 0
      end
    end

    context "collection with works" do
      let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection) }
      let!(:work) { FactoryBot.valkyrie_create(:hyrax_work, member_of_collection_ids: [collection.id]) }

      it 'returns 1' do
        expect(presenter.total_items).to eq 1
      end
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), nil) }

      it 'returns 0' do
        expect(presenter.total_items).to eq 0
      end
    end
  end

  describe "#parent_collection_count" do
    subject { presenter.parent_collection_count }

    let(:parent_collections) { double(Object, documents: parent_docs, response: { "numFound" => parent_docs.size }, total_pages: 1) }

    context('when parent_collections is nil') do
      before do
        allow(presenter).to receive(:parent_collections).and_return(nil)
      end

      it { is_expected.to eq 0 }
    end

    context('when parent_collections is has no collections') do
      let(:parent_docs) { [] }

      it { is_expected.to eq 0 }
    end

    context('when parent_collections is has collections', :active_fedora) do
      let(:collection1) { build(:collection_lw, title: ['col1']) }
      let(:collection2) { build(:collection_lw, title: ['col2']) }
      let!(:parent_docs) { [collection1, collection2] }

      before do
        presenter.parent_collections = parent_collections
      end

      it { is_expected.to eq 2 }
    end
  end

  describe "#collection_type_badge" do
    before do
      allow(collection_type).to receive(:badge_color).and_return("#ffa510")
      allow(presenter).to receive(:collection_type).and_return(collection_type)
    end

    subject { presenter.collection_type_badge }

    it { is_expected.to eq "<span class=\"badge\" style=\"background-color: #ffa510;\">" + collection_type.title + "</span>" }
  end

  describe "#user_can_nest_collection?" do
    before do
      allow(ability).to receive(:can?).with(:deposit, solr_doc).and_return(true)
    end

    subject { presenter.user_can_nest_collection? }

    it { is_expected.to eq true }
  end

  describe "#user_can_create_new_nest_collection?" do
    let(:collection_type) { Hyrax::CollectionType.find_by_gid(collection.collection_type_gid.to_s) }

    before do
      allow(ability).to receive(:can?).with(:create_collection_of_type, collection_type).and_return(true)
    end

    it { expect(presenter.user_can_create_new_nest_collection?).to eq true }
  end

  describe '#show_path' do
    subject { presenter.show_path }

    it { is_expected.to eq "/dashboard/collections/#{solr_doc.id}?locale=en" }
  end

  describe '#editor?' do
    it 'returns true when current_ability can edit the presenter' do
      allow(ability).to receive(:can?).with(:edit, presenter).and_return(true)
      expect(presenter.editor?).to be true
    end

    it 'returns false when current_ability cannot edit the presenter' do
      allow(ability).to receive(:can?).with(:edit, presenter).and_return(false)
      expect(presenter.editor?).to be false
    end
  end

  describe "banner_file" do
    let(:solr_doc) { SolrDocument.new(id: '123') }

    let(:banner_info) do
      CollectionBrandingInfo.new(
        collection_id: "123",
        filename: "banner.gif",
        role: "banner",
        target_url: ""
      )
    end

    let(:logo_info) do
      CollectionBrandingInfo.new(
        collection_id: "123",
        filename: "logo.gif",
        role: "logo",
        alt_txt: "This is the logo",
        target_url: "http://logo.com"
      )
    end

    it "banner check" do
      tempfile = Tempfile.new('my_file')
      banner_info.save(tempfile.path)
      expect(presenter.banner_file).to eq("/branding/123/banner/banner.gif")
    end

    it "logo check" do
      tempfile = Tempfile.new('my_file')
      logo_info.save(tempfile.path)
      expect(presenter.logo_record).to eq([{ file: "logo.gif", file_location: "/branding/123/logo/logo.gif", alttext: "This is the logo", linkurl: "http://logo.com" }])
    end
  end

  describe '#managed_access' do
    context 'when manager' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(true)
      end
      it 'returns Manage label' do
        expect(presenter.managed_access).to eq 'Manage'
      end
    end

    context 'when depositor' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(false)
        allow(ability).to receive(:can?).with(:deposit, solr_doc).and_return(true)
      end
      it 'returns Deposit label' do
        expect(presenter.managed_access).to eq 'Deposit'
      end
    end

    context 'when viewer' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(false)
        allow(ability).to receive(:can?).with(:deposit, solr_doc).and_return(false)
        allow(ability).to receive(:can?).with(:read, solr_doc).and_return(true)
      end
      it 'returns View label' do
        expect(presenter.managed_access).to eq 'View'
      end
    end
  end

  describe '#allow_batch?' do
    context 'when user cannot edit' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(false)
      end

      it 'returns false' do
        expect(presenter.allow_batch?).to be false
      end
    end

    context 'when user can edit' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_doc).and_return(true)
      end

      it 'returns false' do
        expect(presenter.allow_batch?).to be true
      end
    end
  end

  context 'ActiveFedora-specific', :active_fedora do
    let(:active_fedora_collection) do
      build(:collection_lw,
            id: 'adc12v',
            description: ['a nice collection'],
            based_near: ['Over there'],
            title: ['A clever title'],
            keyword: ['neologism'],
            resource_type: ['Collection'],
            related_url: ['http://example.com/'],
            date_created: ['some date'],
            with_solr_document: true)
    end
    let(:active_fedora_solr_hash) { active_fedora_collection.to_solr }
    let(:collection) { active_fedora_collection }
    let(:solr_hash) { active_fedora_solr_hash }

    describe '#collection_type' do
      describe 'when solr_document#collection_type_gid exists' do
        let(:collection) { FactoryBot.build(:collection_lw, collection_type: collection_type) }
        let(:solr_doc) { SolrDocument.new(collection.to_solr) }

        it 'finds the collection type based on the solr_document#collection_type_gid if one exists' do
          expect(presenter.collection_type).to eq(collection_type)
        end
      end
    end

    describe "#resource_type" do
      it 'has resource_type' do
        expect(presenter).to have_attributes resource_type: collection.resource_type
      end
    end

    describe "#terms_with_values" do
      it 'gives the list of terms that have values' do
        expect(presenter.terms_with_values)
          .to contain_exactly(:total_items, :size, :resource_type, :keyword,
                              :date_created, :based_near, :related_url)
      end
    end

    describe('#keyword') { it { is_expected.to have_attributes keyword: collection.keyword } }

    describe('#based_near') { it { is_expected.to have_attributes based_near: collection.based_near } }

    describe('#related_url') { it { is_expected.to have_attributes related_url: collection.related_url } }

    describe('#to_key') { it { expect(presenter.to_key).to eq ['adc12v'] } }

    describe '#size' do
      it 'returns a hard-coded string and issues a deprecation warning' do
        expect(Deprecation).to receive(:warn).once
        expect(presenter.size).to eq('unknown')
      end
    end

    context "total_viewable methods" do
      let(:ability) { double(::Ability, user_groups: ['public'], current_user: user) }
      let(:user) { create(:user) }
      let(:collection) { FactoryBot.create(:collection_lw) }
      let(:solr_hash) { collection.to_solr }

      before { allow(ability).to receive(:admin?).and_return(false) }

      describe "#total_viewable_items", :clean_repo do
        subject { presenter.total_viewable_items }

        it_behaves_like 'a total_viewable method'
        it_behaves_like 'a collection with public collection'
        it_behaves_like 'a collection with public work'
        it_behaves_like 'a collection with private work'

        context "collection with private collection" do
          let!(:work) { build(:private_collection_lw, member_of_collections: [collection]) }

          it { is_expected.to eq 0 }
        end

        context "collection with public work and sub-collection" do
          let!(:work) { create(:public_work, member_of_collections: [collection]) }
          let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

          it { is_expected.to eq 2 }
        end
      end

      describe "#total_viewable_works", :clean_repo do
        subject { presenter.total_viewable_works }

        it_behaves_like 'a total_viewable method'
        it_behaves_like 'a collection with public work and sub-collection'
        it_behaves_like 'a collection with public work'
        it_behaves_like 'a collection with private work'
      end

      describe "#total_viewable_collections", :clean_repo do
        subject { presenter.total_viewable_collections }

        it_behaves_like 'a total_viewable method'
        it_behaves_like 'a collection with public work and sub-collection'
        it_behaves_like 'a collection with public collection'

        context "collection with private collection" do
          let!(:subcollection) { build(:private_collection_lw, member_of_collections: [collection]) }

          it { is_expected.to eq 0 }
        end
      end
    end
  end

  context 'with a flexible metadata profile' do
    subject(:presenter) { described_class.new(flexible_doc, ability) }
    let(:flexible_doc) do
      SolrDocument.new('id' => 'c1', 'has_model_ssim' => [Hyrax.config.collection_model], 'schema_version_ssi' => '1',
                       'call_number_tesim' => ['MS.0951'], 'rights_statement_tesim' => ['http://rightsstatements.org/vocab/InC/1.0/'])
    end
    let(:on_collections) { { 'class' => [Hyrax.config.collection_model, Hyrax.config.admin_set_model] } }
    let(:properties) do
      { 'call_number' => { 'available_on' => on_collections, 'indexing' => ['call_number_tesim'], 'data_type' => 'array' },
        'rights_statement_optional' => { 'name' => 'rights_statement', 'available_on' => on_collections, 'indexing' => ['rights_statement_tesim'],
                                         'data_type' => 'array' } }
    end

    before { allow(Hyrax::FlexibleSchema).to receive_messages(current_version: { 'properties' => properties }, current_schema_id: 1) }

    after do
      described_class.profile_readers.each do |reader|
        [described_class, Hyrax::AdminSetPresenter].each { |klass| klass.send(:remove_method, reader) if klass.method_defined?(reader, false) }
      end
      described_class.profile_readers.clear
    end

    it 'reads a profile property the presenter has no other reader for' do
      expect(presenter.call_number).to eq ['MS.0951']
    end

    it "names a profile property's reader after its name, not its profile key" do
      expect(presenter.rights_statement).to eq ['http://rightsstatements.org/vocab/InC/1.0/']
    end

    it 'reads a single-valued property as its value' do
      properties['shelf'] = { 'available_on' => on_collections, 'indexing' => ['shelf_ssi'], 'data_type' => 'string', 'multiple' => false }
      shelved = described_class.new(SolrDocument.new(flexible_doc.to_h.merge('shelf_ssi' => 'Vault 2')), ability)

      expect(shelved.shelf).to eq 'Vault 2'
    end

    it 'reads a property whose cardinality allows many values as a list' do
      properties['shelf'] = { 'available_on' => on_collections, 'indexing' => ['shelf_ssi'], 'cardinality' => { 'minimum' => 0 } }
      shelved = described_class.new(SolrDocument.new(flexible_doc.to_h.merge('shelf_ssi' => 'Vault 2')), ability)

      expect(shelved.shelf).to eq ['Vault 2']
    end

    it 'matches its class when the profile writes the class name with a leading ::' do
      properties['call_number']['available_on'] = { 'class' => ["::#{Hyrax.config.collection_model.to_s.delete_prefix('::')}"] }

      expect(presenter.profile_property(:call_number)).to be_present
    end

    it 'has no profile entry for a property available only on other classes' do
      properties['shelf_mark'] = { 'available_on' => { 'class' => ['GenericWork'] }, 'indexing' => ['shelf_mark_tesim'] }

      expect(presenter.profile_property(:shelf_mark)).to be_nil
    end

    it 'reads a collection saved under an earlier profile with that profile' do
      allow(Hyrax::FlexibleSchema).to receive(:current_schema_id).and_return(2)
      earlier = properties.deep_merge('call_number' => { 'indexing' => ['call_number_ssim'] })
      allow(Hyrax::FlexibleSchema).to receive(:find_by).with(id: '1').and_return(instance_double(Hyrax::FlexibleSchema, profile: { 'properties' => earlier }))
      saved_earlier = described_class.new(SolrDocument.new(flexible_doc.to_h.merge('call_number_ssim' => ['MS.0950'])), ability)

      expect(saved_earlier.call_number).to eq ['MS.0950']
    end

    it 'loads an earlier profile once per request, however many collections were saved under it' do
      allow(Hyrax::FlexibleSchema).to receive(:current_schema_id).and_return(2)
      allow(Hyrax::FlexibleSchema).to receive(:find_by).with(id: '1').and_return(instance_double(Hyrax::FlexibleSchema, profile: { 'properties' => properties }))
      2.times { described_class.new(flexible_doc, ability).call_number }

      expect(Hyrax::FlexibleSchema).to have_received(:find_by).once
    end

    context 'when a same-named entry is limited to a context' do
      let(:admin_set_model) { Hyrax.config.admin_set_model }
      let(:admin_set) do
        Hyrax::AdminSetPresenter.new(SolrDocument.new('id' => 'a2', 'has_model_ssim' => [admin_set_model], 'schema_version_ssi' => '1',
                                                      'contexts_ssim' => ['closed_context']), ability)
      end

      before do
        classes = [Hyrax.config.collection_model, admin_set_model]
        properties['keyword'] = { 'available_on' => { 'class' => classes }, 'indexing' => ['keyword_tesim'] }
        properties['keyword_closed'] = { 'name' => 'keyword', 'available_on' => { 'class' => classes, 'context' => ['closed_context'] },
                                         'indexing' => ['keyword_tesim', 'admin_only'] }
      end

      it 'uses the unscoped entry, since contexts apply to works' do
        expect(presenter.profile_property(:keyword)['indexing']).not_to include('admin_only')
      end

      it "uses the unscoped entry on an admin set that defines that context" do
        expect(admin_set.profile_property(:keyword)['indexing']).not_to include('admin_only')
      end
    end

    it 'never takes a same-named entry that is not available on the collection class' do
      properties['keyword_works'] = { 'name' => 'keyword', 'available_on' => { 'class' => ['GenericWork'] }, 'indexing' => ['keyword_tesim', 'admin_only'] }
      properties['keyword'] = { 'available_on' => on_collections, 'indexing' => ['keyword_tesim'] }

      expect(presenter.profile_property(:keyword)['indexing']).not_to include('admin_only')
    end

    it "reads a profile property on a flexible admin set, whose readers are recorded on the collection presenter" do
      presenter
      admin_set = Hyrax::AdminSetPresenter.new(SolrDocument.new('id' => 'a1', 'has_model_ssim' => [Hyrax.config.admin_set_model],
                                                                'schema_version_ssi' => '1', 'call_number_tesim' => ['MS.0951']), ability)

      expect(admin_set.readable_term?(:call_number)).to be true
      expect(admin_set[:call_number]).to eq ['MS.0951']
    end

    it "skips a listed field on a collection saved without the profile, even once a flexible collection's reader exists" do
      properties['abstract'] = { 'available_on' => on_collections, 'indexing' => ['abstract_tesim'], 'data_type' => 'array' }
      presenter
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[abstract])
      plain = described_class.new(SolrDocument.new('id' => 'c2', 'has_model_ssim' => [Hyrax.config.collection_model],
                                                   'abstract_tesim' => ['Maps of the harbor.']), ability)

      expect(plain.terms_with_values).to be_empty
    end

    context "when the document's own reader finds nothing under the profile's index keys" do
      let(:summarized) do
        properties['abstract'] = { 'available_on' => on_collections, 'indexing' => ['abstract_ssim'], 'data_type' => 'array' }
        described_class.new(SolrDocument.new(flexible_doc.to_h.merge('abstract_ssim' => ['Maps of the harbor.'])), ability)
      end

      it "reads the property from the profile's index keys" do
        expect(summarized.abstract).to eq ['Maps of the harbor.']
      end

      it 'looks it up by term the same way' do
        expect(summarized[:abstract]).to eq ['Maps of the harbor.']
      end
    end

    it "keeps the document's own reading of a property when it has one" do
      properties['date_modified'] = { 'available_on' => on_collections, 'indexing' => ['date_modified_dtsi'], 'data_type' => 'string' }
      dated = described_class.new(SolrDocument.new(flexible_doc.to_h.merge('date_modified_dtsi' => '2026-10-01T12:00:00Z')), ability)

      expect(dated.date_modified).to eq Date.new(2026, 10, 1)
    end

    it 'looks up through the document a term only an admin set presenter has a reader for' do
      properties['alternative_title'] = { 'available_on' => { 'class' => [Hyrax.config.admin_set_model] }, 'indexing' => ['alternative_title_tesim'],
                                          'data_type' => 'array' }
      Hyrax::AdminSetPresenter.new(SolrDocument.new('id' => 'a3', 'has_model_ssim' => [Hyrax.config.admin_set_model], 'schema_version_ssi' => '1'), ability)
      titled = described_class.new(SolrDocument.new(flexible_doc.to_h.merge('alternative_title_tesim' => ['Harbor papers'])), ability)

      expect(titled[:alternative_title]).to eq ['Harbor papers']
    end

    it 'looks up such a property by term, as the collection page does' do
      expect(presenter[:call_number]).to eq ['MS.0951']
    end

    it 'builds no compound schema while defining readers' do
      allow(Hyrax::CompoundSchema).to receive(:for_solr_document).and_call_original
      presenter

      expect(Hyrax::CompoundSchema).not_to have_received(:for_solr_document)
    end

    it "reads a property's indexed values from the current profile, not the one that defined its reader" do
      presenter.call_number
      properties['call_number']['indexing'] = ['call_number_ssim']
      later = SolrDocument.new(flexible_doc.to_h.merge('call_number_ssim' => ['MS.0952']))

      expect(described_class.new(later, ability).call_number).to eq ['MS.0952']
    end

    it "gives a collection saved without the profile no profile reader's value" do
      presenter
      plain = described_class.new(SolrDocument.new('id' => 'c2', 'has_model_ssim' => [Hyrax.config.collection_model],
                                                   'call_number_tesim' => ['MS.0951']), ability)

      expect(plain.profile_reader?(:call_number)).to be false
    end
  end

  describe '#terms with Hyrax.config.collection_terms' do
    subject(:presenter) { described_class.new(SolrDocument.new('id' => 'c1', 'has_model_ssim' => [Hyrax.config.collection_model]), ability) }

    it "lists the presenter's terms when no list is set" do
      expect(presenter.terms).to eq described_class.terms + presenter.compound_terms
    end

    it "lists the configured fields, in order, on a collection page" do
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[abstract creator title])

      expect(presenter.terms).to eq %i[abstract creator title]
    end

    it 'skips a configured field the document has but the presenter cannot read' do
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[title abstract])
      summarized = described_class.new(SolrDocument.new('id' => 'c1', 'has_model_ssim' => [Hyrax.config.collection_model],
                                                        'title_tesim' => ['Harbor Records'], 'abstract_tesim' => ['Maps of the harbor.']), ability)

      expect(summarized.terms_with_values).to eq %i[title]
    end

    it 'skips a configured term only the presenter defines when listing terms with values' do
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[title total_viewable_items])
      titled = described_class.new(SolrDocument.new('id' => 'c1', 'has_model_ssim' => [Hyrax.config.collection_model],
                                                    'title_tesim' => ['Harbor Records']), ability)

      expect(titled.terms_with_values).to eq %i[title]
    end

    it "leaves an admin set's terms alone" do
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[abstract creator title])
      admin_set = Hyrax::AdminSetPresenter.new(SolrDocument.new('id' => 'a1', 'has_model_ssim' => ['AdminSetResource']), ability)

      expect(admin_set.terms).not_to eq %i[abstract creator title]
    end
  end
end
