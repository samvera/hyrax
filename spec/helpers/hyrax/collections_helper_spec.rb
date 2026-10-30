# frozen_string_literal: true
RSpec.describe Hyrax::CollectionsHelper, :clean_repo do
  let(:user) { FactoryBot.create(:user, groups: ['admin']) }
  let(:ability) { Ability.new(user) }

  before do
    # Stub route because helper specs don't handle engine routes
    # https://github.com/rspec/rspec-rails/issues/1250
    allow(view).to receive(:collection_path) do |collection|
      id = collection.respond_to?(:id) ? collection.id : collection
      "/collections/#{id}"
    end
  end

  describe '#available_child_collections' do
    let(:repository) { Blacklight::Solr::Repository.new(bl_config) }
    let(:bl_config) { CatalogController.blacklight_config }

    before do
      allow(controller).to receive(:blacklight_config).and_return(bl_config)
      allow(controller).to receive(:repository).and_return(repository)
      allow(controller).to receive(:current_ability).and_return(ability)
      allow(controller).to receive(:search_state_class).and_return(nil)
    end

    it 'gives an empty set for a missing collection' do
      expect(helper.available_child_collections(collection: nil)).to be_empty
    end

    it 'gives a list of available collections' do
      valkyrie_create(:hyrax_collection) # other collection
      current_collection = valkyrie_create(:hyrax_collection)

      expect(helper.available_child_collections(collection: current_collection))
        .not_to be_empty
    end

    context 'with a presenter' do
      let(:collection) { valkyrie_create(:hyrax_collection) }
      let(:presenter)  { Hyrax::CollectionPresenter.new(solr_doc, ability) }
      let(:solr_doc)   { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: collection).to_solr) }

      before do
        valkyrie_create(:hyrax_collection) # other collection
      end

      it 'gives a list of available collections' do
        expect(helper.available_child_collections(collection: presenter))
          .not_to be_empty
      end
    end
  end

  describe '#render_collection_links' do
    before do
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'when a GenericWork does not belongs to any collections', :clean_repo do
      let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork']) }

      it 'renders nothing' do
        expect(helper.render_collection_links(work_doc)).to be_nil
      end
    end

    context 'when a GenericWork belongs to collections' do
      let(:coll_ids) { ['111', '222'] }
      let(:coll_titles) { ['Collection 111', 'Collection 222'] }
      let(:coll1_attrs) { { id: coll_ids[0], title_tesim: [coll_titles[0]] } }
      let(:coll2_attrs) { { id: coll_ids[1], title_tesim: [coll_titles[1]] } }
      let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork'], member_of_collection_ids_ssim: coll_ids) }

      before do
        Hyrax::SolrService.add(coll1_attrs)
        Hyrax::SolrService.add(coll2_attrs)
        Hyrax::SolrService.commit
      end

      it 'renders a list of links to the collections' do
        expect(helper.render_collection_links(work_doc)).to match(/Is part of/i)
        expect(helper.render_collection_links(work_doc)).to match("href=\"/collections/#{coll_ids[0]}\"")
        expect(helper.render_collection_links(work_doc)).to match("href=\"/collections/#{coll_ids[1]}\"")
        expect(helper.render_collection_links(work_doc)).to match(coll_titles[0])
        expect(helper.render_collection_links(work_doc)).to match(coll_titles[1])
      end
    end
  end

  describe '#render_other_collection_links' do
    before do
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'when a GenericWork belongs to one collection' do
      let(:coll_ids) { ['111'] }
      let(:coll_titles) { ['Collection 111'] }
      let(:coll1_attrs) { { id: coll_ids[0], title_tesim: [coll_titles[0]] } }
      let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork'], member_of_collection_ids_ssim: coll_ids) }

      before do
        Hyrax::SolrService.add(coll1_attrs)
        Hyrax::SolrService.commit
      end

      it 'renders nothing' do
        expect(helper.render_other_collection_links(work_doc, coll_ids[0])).to be_nil
      end
    end

    context 'when a GenericWork belongs to more than one collection' do
      let(:coll_ids) { ['111', '222'] }
      let(:coll_titles) { ['Collection 111', 'Collection 222'] }
      let(:coll1_attrs) { { id: coll_ids[0], title_tesim: [coll_titles[0]] } }
      let(:coll2_attrs) { { id: coll_ids[1], title_tesim: [coll_titles[1]] } }
      let!(:work_doc) { SolrDocument.new(id: '123', title_tesim: ['My GenericWork'], member_of_collection_ids_ssim: coll_ids) }

      before do
        Hyrax::SolrService.add(coll1_attrs)
        Hyrax::SolrService.add(coll2_attrs)
        Hyrax::SolrService.commit
      end

      it 'renders a list of links to the collections' do
        expect(helper.render_other_collection_links(work_doc, coll_ids[0])).to match(/This work also belongs to/i)
        expect(helper.render_other_collection_links(work_doc, coll_ids[0])).to match("href=\"/collections/#{coll_ids[1]}\"")
        expect(helper.render_other_collection_links(work_doc, coll_ids[0])).to match(coll_titles[1])
      end
    end
  end

  describe '#collection_search_parameters?' do
    subject { helper }

    context "when cq is set" do
      before { allow(helper).to receive(:params).and_return(cq: 'foo') }
      it { is_expected.to be_collection_search_parameters }
    end

    context "when cq is not set" do
      before { allow(helper).to receive(:params).and_return(cq: '') }
      it { is_expected.not_to be_collection_search_parameters }
    end
  end

  describe "button_for_remove_selected_from_collection" do
    let(:collection) { valkyrie_create(:hyrax_collection) }

    it "creates a button to the collections delete path" do
      str = button_for_remove_selected_from_collection collection
      doc = Nokogiri::HTML(str)
      form = doc.xpath('//form').first
      expect(form.attr('action')).to eq hyrax.dashboard_collection_path(collection)
      i = form.xpath('.//input')[2]
      expect(i.attr('value')).to eq("Remove From Collection")
      expect(i.attr('name')).to eq("commit")
    end

    it "creates a button with my text" do
      str = button_for_remove_selected_from_collection collection, "Remove My Button"
      doc = Nokogiri::HTML(str)
      form = doc.css('form').first
      expect(form.attr('action')).to eq hyrax.dashboard_collection_path(collection)
      expect(form.css('input[type="submit"]').attr('value').value).to eq "Remove My Button"
    end
  end

  describe "collection_type_label" do
    context "when the CollectionType is found" do
      let(:test_collection_type) { FactoryBot.create(:collection_type) }

      it "returns the CollectionType title" do
        expect(collection_type_label(test_collection_type.to_global_id))
          .to eq test_collection_type.title
      end
    end

    context "when the CollectionType cannot be found" do
      it "returns the input gid unchanged" do
        expect(collection_type_label(nil)).to eq "User Collection"
      end
    end
  end

  describe '#append_collection_type_url' do
    let(:url) { "http://example.com" }
    context "when a provided url has no querystring" do
      it 'returns the url with added collection_type_id' do
        expect(append_collection_type_url(url, '1')).to eq "#{url}?collection_type_id=1"
      end
    end

    context "when a provided url has an existing querystring" do
      let(:url) { "http://example.com?bob=ross" }
      it 'return the url with added collection_type_id' do
        expect(append_collection_type_url(url, '1')).to eq "#{url}&collection_type_id=1"
      end
    end
  end

  describe "#collection_permission_template_form" do
    subject { helper.collection_permission_template_form_for(form: form) }
    context "when receiving an admin_set_form" do
      let(:ability)    { Ability.new(create(:user)) }
      let(:repository) { double }
      let(:model)      { build(:admin_set, description: ['one']) }
      let(:form)       { Hyrax::Forms::AdminSetForm.new(model, ability, repository) }

      it 'returns the permission_template_form' do
        expect(subject).to be_instance_of Hyrax::Forms::PermissionTemplateForm
        expect(subject.model).to be_instance_of Hyrax::PermissionTemplate
      end
    end

    context "when receiving an administrative_set_form" do
      let(:form)      { Hyrax::Forms::AdministrativeSetForm.new(admin_set) }
      let(:admin_set) { Hyrax::AdministrativeSet.new }

      it 'returns the permission_template_form' do
        expect(subject).to be_instance_of Hyrax::Forms::PermissionTemplateForm
        expect(subject.model).to be_instance_of Hyrax::PermissionTemplate
      end
    end

    context "when receiving an collection_form", :active_fedora do
      let(:ability)    { Ability.new(create(:user)) }
      let(:repository) { double }
      let(:model)      { build(:collection_lw) }
      let(:form)       { Hyrax::Forms::CollectionForm.new(model, ability, repository) }

      it 'returns the permission_template_form' do
        expect(subject).to be_instance_of Hyrax::Forms::PermissionTemplateForm
        expect(subject.model).to be_instance_of Hyrax::PermissionTemplate
      end
    end

    context "when receiving an pcdm_collection_form" do
      let(:form)      { Hyrax::Forms::PcdmCollectionForm.new(admin_set) }
      let(:admin_set) { Hyrax::PcdmCollection.new }

      it 'returns the permission_template_form' do
        expect(subject).to be_instance_of Hyrax::Forms::PermissionTemplateForm
        expect(subject.model).to be_instance_of Hyrax::PermissionTemplate
      end
    end
  end

  describe '#collection_terms_for on an admin set that defines a context' do
    let(:admin_model) { Hyrax.config.admin_set_model.to_s.delete_prefix('::') }
    let(:profile) do
      { 'classes' => { admin_model => {} },
        'properties' => {
          'keyword' => { 'available_on' => { 'class' => [admin_model] }, 'indexing' => ['keyword_tesim'], 'view' => { 'html_dl' => true } },
          'keyword_closed' => { 'name' => 'keyword', 'available_on' => { 'class' => [admin_model], 'context' => ['closed_context'] },
                                'indexing' => ['keyword_tesim'], 'view' => { 'html_dl' => true, 'collection_page' => false } }
        } }
    end
    let(:schema) { Hyrax::FlexibleSchema.new(profile: profile).tap { |record| record.save(validate: false) } }
    let(:admin_set) do
      Hyrax::AdminSetPresenter.new(SolrDocument.new('id' => 'a1', 'has_model_ssim' => [admin_model], 'schema_version_ssi' => schema.id.to_s,
                                                    'contexts_ssim' => ['closed_context'], 'keyword_tesim' => ['harbors']), Ability.new(nil))
    end

    before do
      allow(Hyrax::FlexibleSchema).to receive_messages(current_version: profile, current_schema_id: schema.id)
      allow(helper).to receive(:current_user).and_return(nil)
    end

    after { Hyrax::CollectionPresenter.profile_readers.clear }

    it "takes the property's view settings from its entry with no context" do
      expect(helper.collection_terms_for(admin_set, dynamic: true)).to include(:keyword)
    end
  end

  describe '#collection_terms_for' do
    let(:document) do
      SolrDocument.new('id' => 'c1', 'has_model_ssim' => [Hyrax.config.collection_model], 'schema_version_ssi' => '1',
                       'title_tesim' => ['Harbor Records'], 'abstract_tesim' => ['Maps of the harbor.'],
                       'call_number_tesim' => ['MS.0951'], 'resource_link_tesim' => ['https://example.com/harbor'])
    end
    let(:presenter) { Hyrax::CollectionPresenter.new(document, Ability.new(nil)) }
    let(:on_collections) { { 'class' => [Hyrax.config.collection_model] } }
    let(:properties) do
      { 'abstract' => { 'available_on' => on_collections, 'indexing' => ['abstract_tesim'], 'data_type' => 'array',
                        'display_label' => { 'default' => 'Summary' }, 'view' => { 'html_dl' => true } },
        'call_number' => { 'available_on' => on_collections, 'indexing' => ['call_number_tesim'], 'data_type' => 'array', 'view' => { 'html_dl' => true } },
        'resource_link' => { 'available_on' => on_collections, 'indexing' => ['resource_link_tesim'], 'data_type' => 'array',
                             'view' => { 'html_dl' => true, 'collection_page' => false } },
        'admin_note' => { 'available_on' => on_collections, 'indexing' => ['admin_note_tesim', 'admin_only'], 'data_type' => 'array',
                          'view' => { 'html_dl' => true } },
        'donors' => { 'available_on' => on_collections, 'type' => 'hash', 'view' => { 'html_dl' => true, 'collection_page' => false } },
        'relationships' => { 'available_on' => on_collections, 'type' => 'hash', 'view' => { 'html_dl' => true, 'display' => 'card' } } }
    end

    before do
      allow(Hyrax::FlexibleSchema).to receive_messages(current_version: { 'properties' => properties }, current_schema_id: 1)
      allow(presenter).to receive(:editor?).and_return(false)
      allow(helper).to receive(:compound_card_field?) { |_presenter, field| field.to_sym == :relationships }
      allow(helper).to receive(:current_user).and_return(nil)
    end

    after do
      Hyrax::CollectionPresenter.profile_readers.each do |reader|
        Hyrax::CollectionPresenter.send(:remove_method, reader) if Hyrax::CollectionPresenter.method_defined?(reader, false)
      end
      Hyrax::CollectionPresenter.profile_readers.clear
    end

    it "lists the presenter's own terms with values, as an app may define them, when no list is set" do
      allow(presenter).to receive(:terms_with_values).and_return(%i[total_items abstract])

      expect(helper.collection_terms_with_values(presenter)).to eq %i[total_items abstract]
    end

    it "keeps the presenter's terms when no list is set and the page does not ask for the profile's" do
      expect(helper.collection_terms_for(presenter)).to eq presenter.terms
    end

    it "leaves out of the presenter's terms a field the profile limits to admins or editors" do
      properties['abstract']['indexing'] << 'editor_only'
      allow(presenter).to receive(:terms).and_return(%i[total_items abstract admin_note call_number])

      expect(helper.collection_terms_for(presenter)).to eq %i[total_items call_number]
    end

    it "leaves out of the presenter's terms a field, compound or not, the profile keeps off collection pages" do
      properties['call_number']['view']['collection_page'] = false
      allow(presenter).to receive(:terms).and_return(%i[total_items abstract call_number donors])

      expect(helper.collection_terms_for(presenter)).to eq %i[total_items abstract]
    end

    it "keeps a field limited to admins or editors for a viewer who is one" do
      properties['abstract']['indexing'] << 'editor_only'
      admin = instance_double(::User, admin?: true)
      allow(helper).to receive(:current_user).and_return(admin)
      allow(presenter).to receive_messages(terms: %i[abstract admin_note], editor?: true)

      expect(helper.collection_terms_for(presenter)).to eq %i[abstract admin_note]
    end

    it "leaves out a field whose profile entry is marked admin-only" do
      properties['call_number']['admin_only'] = true

      expect(helper.collection_terms_for(presenter, dynamic: true)).to eq %i[abstract]
    end

    it "shows an admin who does not edit the collection its admin-only fields, not its editor-only ones" do
      properties['abstract']['indexing'] << 'editor_only'
      allow(helper).to receive(:current_user).and_return(instance_double(::User, admin?: true))

      expect(helper.collection_terms_for(presenter, dynamic: true)).to eq %i[call_number admin_note]
    end

    it "shows an editor who is not an admin its editor-only fields, not its admin-only ones" do
      properties['abstract']['indexing'] << 'editor_only'
      allow(helper).to receive(:current_user).and_return(instance_double(::User, admin?: false))
      allow(presenter).to receive(:editor?).and_return(true)

      expect(helper.collection_terms_for(presenter, dynamic: true)).to eq %i[abstract call_number]
    end

    it "lists the profile's properties a collection page may show, in profile order, when the page asks for them" do
      expect(helper.collection_terms_for(presenter, dynamic: true)).to eq %i[abstract call_number]
    end

    it 'keeps a featured property on the collection page' do
      properties['call_number']['view']['position'] = 'featured'

      expect(helper.collection_terms_for(presenter, dynamic: true)).to include(:call_number)
    end

    context 'with Hyrax.config.collection_terms' do
      before { allow(Hyrax.config).to receive(:collection_terms).and_return(%i[call_number title abstract resource_link admin_note relationships]) }

      it 'lists the configured properties in order, leaving out those the profile lacks, keeps off collection pages, cards or hides' do
        expect(helper.collection_terms_for(presenter)).to eq %i[call_number abstract]
      end

      it "uses the list even where the page asks for the profile's" do
        expect(helper.collection_terms_for(presenter, dynamic: true)).to eq %i[call_number abstract]
      end

      it "labels a listed property with the profile's label" do
        expect(helper.collection_metadata_label(presenter, :abstract)).to eq 'Summary'
      end

      context 'with a controlled property' do
        let(:catalog_config) { Blacklight::Configuration.new }

        before do
          properties['subject'] = { 'available_on' => on_collections, 'indexing' => %w[subject_tesim subject_sim], 'data_type' => 'array',
                                    'view' => { 'html_dl' => true, 'render_as' => 'faceted' } }
          allow(Hyrax.config).to receive(:collection_terms).and_return(%i[subject])
          config = catalog_config
          helper.define_singleton_method(:blacklight_config) { config }
        end

        def subject_link(document)
          collection = Hyrax::CollectionPresenter.new(document, Ability.new(nil))
          link = Capybara.string(helper.collection_metadata_value(collection, :subject).to_s).find('a')
          [link.text, CGI.unescape(link['href'])]
        end

        it 'shows its indexed label and links through the label facet the catalog registers' do
          catalog_config.add_facet_field 'subject_label_sim'
          labeled = SolrDocument.new(document.to_h.merge('subject_tesim' => ['http://id.loc.gov/subjects/sh1'], 'subject_label_tesim' => ['Harbors']))

          text, href = subject_link(labeled)
          expect(text).to eq 'Harbors'
          expect(href).to include('f[subject_label_sim][]=Harbors')
        end

        it 'shows the stored value and links through its own facet when no label is indexed' do
          unlabeled = SolrDocument.new(document.to_h.merge('subject_tesim' => ['http://id.loc.gov/subjects/sh1']))

          text, href = subject_link(unlabeled)
          expect(text).to eq 'http://id.loc.gov/subjects/sh1'
          expect(href).to include('f[subject_sim][]=http://id.loc.gov/subjects/sh1')
        end
      end

      it "renders a listed property's value with the profile's view settings" do
        expect(helper.collection_metadata_value(presenter, :call_number)).to include('MS.0951')
      end

      it "renders a listed property whose profile render term the presenter cannot read as before" do
        properties['based_near'] = { 'available_on' => on_collections, 'indexing' => ['based_near_tesim'], 'display_label' => { 'default' => 'Location' },
                                     'view' => { 'html_dl' => true, 'render_term' => 'based_near_label' } }
        located = Hyrax::CollectionPresenter.new(document, Ability.new(nil))
        allow(located).to receive(:based_near).and_return(['Knoxville'])
        allow(Hyrax::PresenterRenderer).to receive(:new).and_return(instance_double(Hyrax::PresenterRenderer, value: 'Knoxville'))

        expect(helper.collection_metadata_value(located, :based_near)).to eq 'Knoxville'
      end

      it "labels a listed property with the profile's label even when the presenter cannot read its render term" do
        properties['based_near'] = { 'available_on' => on_collections, 'indexing' => ['based_near_tesim'], 'display_label' => { 'default' => 'Place of creation' },
                                     'view' => { 'html_dl' => true, 'render_term' => 'based_near_label' } }
        located = Hyrax::CollectionPresenter.new(document, Ability.new(nil))

        expect(helper.collection_metadata_label(located, :based_near)).to eq 'Place of creation'
      end

      it "labels a listed based_near with the label key Hyrax's profile gives it" do
        properties['based_near'] = { 'available_on' => on_collections, 'indexing' => ['based_near_tesim'],
                                     'display_label' => { 'default' => 'blacklight.search.fields.show.based_near_label_tesim' },
                                     'view' => { 'html_dl' => true, 'render_term' => 'based_near_label' } }
        located = Hyrax::CollectionPresenter.new(document, Ability.new(nil))

        expect(helper.collection_metadata_label(located, :based_near)).to eq 'Location'
      end

      it 'skips a listed term only the presenter defines, which the page cannot look up' do
        allow(Hyrax.config).to receive(:collection_terms).and_return(%i[title total_viewable_items])
        plain = Hyrax::CollectionPresenter.new(SolrDocument.new('id' => 'c4', 'has_model_ssim' => [Hyrax.config.collection_model],
                                                                'title_tesim' => ['Harbor Records']), Ability.new(nil))

        expect(helper.collection_terms_with_values(plain)).to eq %i[title]
      end

      it "ignores another collection's profile readers on a collection saved without the profile" do
        presenter.abstract
        plain = Hyrax::CollectionPresenter.new(SolrDocument.new('id' => 'c3', 'has_model_ssim' => [Hyrax.config.collection_model],
                                                                'title_tesim' => ['Harbor Records'], 'call_number_tesim' => ['MS.0951']),
                                               Ability.new(nil))

        expect(helper.collection_terms_with_values(plain)).to eq %i[title]
      end
    end
  end
end
