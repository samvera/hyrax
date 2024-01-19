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
end
