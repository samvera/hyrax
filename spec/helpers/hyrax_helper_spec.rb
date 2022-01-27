# frozen_string_literal: true
def new_state
  Blacklight::SearchState.new({}, CatalogController.blacklight_config)
end

RSpec.describe HyraxHelper, type: :helper do
  describe "show_transfer_request_title" do
    let(:sender) { create(:user) }
    let(:user) { create(:user) }

    context "when work is canceled" do
      let(:request) do
        instance_double(ProxyDepositRequest,
                        deleted_work?: false,
                        canceled?: true,
                        to_s: 'Test work')
      end

      subject { helper.show_transfer_request_title request }

      it { expect(subject).to eq 'Test work' }
    end
  end

  describe '#render_notifications' do
    let(:mailbox) { double('mailbox', unread_count: unread_count, label: 'Foobar') }

    subject { helper.render_notifications(user: nil) }

    before do
      allow(UserMailbox).to receive(:new).and_return(mailbox)
    end

    context 'with unread messages' do
      let(:unread_count) { 10 }

      it 'renders with label-danger and is visible' do
        expect(subject).to eq '<a aria-label="Foobar" class="notify-number" href="/notifications"><span class="fa fa-bell"></span>' \
                              "\n" \
                              '<span class="count label label-danger">10</span></a>'
      end
    end

    context 'with no unread messages' do
      let(:unread_count) { 0 }

      it 'renders with label-default and is invisible' do
        expect(subject).to eq '<a aria-label="Foobar" class="notify-number" href="/notifications"><span class="fa fa-bell"></span>' \
                              "\n" \
                              '<span class="count label invisible label-default">0</span></a>'
      end
    end
  end

  describe '#available_translations' do
    subject { helper.available_translations }

    it do
      is_expected.to eq('de' => 'Deutsch',
                        'en' => 'English',
                        'es' => 'Español',
                        'fr' => 'Français',
                        'it' => 'Italiano',
                        'pt-BR' => 'Português do Brasil',
                        'zh' => '中文')
    end
  end

  context 'link helpers' do
    before do
      allow(helper).to receive(:search_action_path) do |*args|
        search_catalog_path(*args)
      end
      allow(helper).to receive(:search_state).and_return(new_state)
    end

    describe "#link_to_facet_list" do
      context "with values" do
        subject { helper.link_to_facet_list(['car', 'truck'], 'vehicle_type') }

        it "joins the values" do
          expect(helper).to receive(:search_state).exactly(2).times
          car_link   = search_catalog_path(f: { 'vehicle_type_sim' => ['car'] })
          truck_link = search_catalog_path(f: { 'vehicle_type_sim' => ['truck'] })
          expect(subject).to eq "<a href=\"#{car_link}\">car</a>, <a href=\"#{truck_link}\">truck</a>"
          expect(subject).to be_html_safe
        end
      end

      context "without values" do
        subject { helper.link_to_facet_list([], 'vehicle_type') }

        it "shows the default text" do
          expect(subject).to eq "No value entered"
        end
      end
    end

    describe '#index_field_link' do
      let(:args) do
        {
          config: { field_name: 'contributor' },
          value: ['Fritz Lang', 'Mel Brooks']
        }
      end

      subject { helper.index_field_link(args) }

      it 'returns a link' do
        expect(subject).to be_html_safe
        expect(subject).to eq '<a href="/catalog?q=%22Fritz+Lang%22&amp;search_field=contributor">Fritz Lang</a>, ' \
                            + '<a href="/catalog?q=%22Mel+Brooks%22&amp;search_field=contributor">Mel Brooks</a>'
      end
    end
  end

  describe "#link_to_each_facet_field" do
    subject { helper.link_to_each_facet_field(options) }

    context "with helper_facet and default separator" do
      let(:options) { { config: { helper_facet: "document_types_sim".to_sym }, value: ["Imaging > Object Photography"] } }

      it do
        is_expected.to eq("<a href=\"/catalog?f%5Bdocument_types_sim%5D%5B%5D=Imaging\">" \
                             "Imaging</a> &gt; " \
                             "<a href=\"/catalog?f%5Bdocument_types_sim%5D%5B%5D=Object+Photography\">Object Photography</a>")
      end
    end

    context "with helper_facet and optional separator" do
      let(:options) { { config: { helper_facet: "document_types_sim".to_sym, separator: " : " }, value: ["Imaging : Object Photography"] } }

      it do
        is_expected.to eq("<a href=\"/catalog?f%5Bdocument_types_sim%5D%5B%5D=Imaging\">" \
                             "Imaging</a> : " \
                             "<a href=\"/catalog?f%5Bdocument_types_sim%5D%5B%5D=Object+Photography\">Object Photography</a>")
      end
    end

    context "with :output_separator" do
      let(:options) do
        { config: { helper_facet: "document_types_sim".to_sym, output_separator: ' ~ ', separator: ":" }, value: ["Imaging : Object Photography"] }
      end

      it do
        is_expected.to eq("<a href=\"/catalog?f%5Bdocument_types_sim%5D%5B%5D=Imaging\">" \
                             "Imaging</a> ~ " \
                             "<a href=\"/catalog?f%5Bdocument_types_sim%5D%5B%5D=Object+Photography\">Object Photography</a>")
      end
    end

    context "with :no_spaces_around_separator" do
      let(:options) do
        { config: { helper_facet: "document_types_sim".to_sym, output_separator: '~', separator: ":" }, value: ["Imaging : Object Photography"] }
      end

      it do
        is_expected.to eq("<a href=\"/catalog?f%5Bdocument_types_sim%5D%5B%5D=Imaging\">" \
                             "Imaging</a>~" \
                             "<a href=\"/catalog?f%5Bdocument_types_sim%5D%5B%5D=Object+Photography\">Object Photography</a>")
      end
    end
  end

  describe "#collection_thumbnail" do
    let(:document) { SolrDocument.new(has_model_ssim: ['Collection']) }

    subject { helper.collection_thumbnail(document) }

    it { is_expected.to eq '<span class="fa fa-cubes collection-icon-search"></span>' }
  end

  describe "#link_to_telephone" do
    subject { helper.link_to_telephone(user) }

    context "when user is set" do
      let(:user) { mock_model(User, telephone: '867-5309') }

      it { is_expected.to eq "<a href=\"wtai://wp/mc;867-5309\">867-5309</a>" }
    end
    context "when user is not set" do
      let(:user) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#current_search_parameters" do
    context "when the user is not in the dashboard" do
      it "is whatever q is" do
        allow(helper).to receive(:params).and_return(controller: "catalog", q: "foo")
        expect(helper.current_search_parameters).to eq("foo")
      end
    end

    context "when the user is on any dashboard page" do
      it "is ignored on dashboard" do
        allow(helper).to receive(:params).and_return(controller: "hyrax/dashboard", q: "foo")
        expect(helper.current_search_parameters).to be_nil
      end

      it "is ignored on dashboard works, collections, highlights and shares" do
        allow(helper).to receive(:params).and_return(controller: "hyrax/my/works", q: "foo")
        expect(helper.current_search_parameters).to be_nil
        allow(helper).to receive(:params).and_return(controller: "hyrax/my/collections", q: "foo")
        expect(helper.current_search_parameters).to be_nil
        allow(helper).to receive(:params).and_return(controller: "hyrax/my/highlights", q: "foo")
        expect(helper.current_search_parameters).to be_nil
        allow(helper).to receive(:params).and_return(controller: "hyrax/my/shares", q: "foo")
        expect(helper.current_search_parameters).to be_nil
      end
    end
  end

  describe "#search_form_action" do
    context "when the user is not in the dashboard" do
      it "returns the catalog index path" do
        allow(helper).to receive(:params).and_return(controller: "foo")
        expect(helper.search_form_action).to eq(search_catalog_path)
      end
    end

    context "when the user is on the dashboard page" do
      it "defaults to My Works" do
        allow(helper).to receive(:params).and_return(controller: "hyrax/dashboard")
        expect(helper.search_form_action).to eq(hyrax.my_works_path)
      end
    end

    context "when the user is on the 'all works' tab on the dashboard page" do
      it "returns the dashboard works path" do
        allow(helper).to receive(:params).and_return(controller: "hyrax/dashboard/works")
        expect(helper.search_form_action).to eq(hyrax.dashboard_works_path)
      end
    end

    context "when the user is on the my works page" do
      it "returns the my dashboard works path" do
        allow(helper).to receive(:params).and_return(controller: "hyrax/my/works")
        expect(helper.search_form_action).to eq(hyrax.my_works_path)
      end
    end

    context "when the user is on the my collections page" do
      it "returns the my dashboard collections path" do
        allow(helper).to receive(:params).and_return(controller: "hyrax/my/collections")
        expect(helper.search_form_action).to eq(hyrax.my_collections_path)
      end
    end

    context "when the user is on the all collections page" do
      it "returns the all dashboard collections path" do
        allow(helper).to receive(:params).and_return(controller: "hyrax/dashboard/collections")
        expect(helper.search_form_action).to eq(hyrax.dashboard_collections_path)
      end
    end

    context "when the user is on the my highlights page" do
      it "returns the my dashboard highlights path" do
        allow(helper).to receive(:params).and_return(controller: "hyrax/my/highlights")
        expect(helper.search_form_action).to eq(hyrax.dashboard_highlights_path)
      end
    end

    context "when the user is on the my shares page" do
      it "returns the my dashboard shares path" do
        allow(helper).to receive(:params).and_return(controller: "hyrax/my/shares")
        expect(helper.search_form_action).to eq(hyrax.dashboard_shares_path)
      end
    end
  end

  describe '#zotero_label' do
    subject { helper }

    it { is_expected.to respond_to(:zotero_label) }
  end

  describe "#iconify_auto_link" do
    let(:text)              { 'Foo < http://www.example.com. & More text' }
    let(:linked_text)       { 'Foo &lt; <a href="http://www.example.com"><span class="fa fa-external-link"></span> http://www.example.com</a>. &amp; More text' }
    let(:document)          { SolrDocument.new(has_model_ssim: ['GenericWork'], id: 512, title_tesim: text, description_tesim: text) }
    let(:blacklight_config) { CatalogController.blacklight_config }

    before do
      allow(controller).to receive(:action_name).and_return('index')
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
    end
    it "boring String argument" do
      expect(helper.iconify_auto_link('no escapes or links necessary')).to eq 'no escapes or links necessary'
      expect(helper.iconify_auto_link('no escapes or links necessary', false)).to eq 'no escapes or links necessary'
    end
    context "interesting String argument" do
      subject { helper.iconify_auto_link(text) }

      it "escapes input" do
        expect(subject).to start_with('Foo &lt;').and end_with('. &amp; More text')
      end
      it "adds links" do
        expect(subject).to include('<a href="http://www.example.com">')
      end
      it "adds icons" do
        expect(subject).to include('class="fa fa-external-link"')
      end
    end

    context "when using a hash argument" do
      subject { helper.iconify_auto_link(arg) }

      describe "auto-linking in the title" do
        let(:arg) { { document: document, value: [text], config: blacklight_config.index_fields['title_tesim'], field: 'title_tesim' } }

        it { is_expected.to eq(linked_text) }
      end

      describe "auto-linking in the description" do
        let(:arg) { { document: document, value: [text], config: blacklight_config.index_fields['description_tesim'], field: 'description_tesim' } }

        it { is_expected.to eq(linked_text) }
      end
    end
  end

  describe "#license_links" do
    it "maps the url to a link with a label" do
      expect(helper.license_links(
               value: ["http://creativecommons.org/publicdomain/zero/1.0/"]
             )).to eq("<a href=\"http://creativecommons.org/publicdomain/zero/1.0/\">Creative Commons CC0 1.0 Universal</a>")
    end

    it "converts multiple licenses to a sentence" do
      expect(helper.license_links(
               value: ["http://creativecommons.org/publicdomain/zero/1.0/",
                       "http://creativecommons.org/publicdomain/mark/1.0/",
                       "http://www.europeana.eu/portal/rights/rr-r.html"]
             )).to eq("<a href=\"http://creativecommons.org/publicdomain/zero/1.0/\">Creative Commons CC0 1.0 Universal</a>, " \
               "<a href=\"http://creativecommons.org/publicdomain/mark/1.0/\">Creative Commons Public Domain Mark 1.0</a>, " \
               "and <a href=\"http://www.europeana.eu/portal/rights/rr-r.html\">All rights reserved</a>")
    end
  end

  describe "#rights_statment_links" do
    it "maps the url to a link with a label" do
      expect(helper.rights_statement_links(
               value: ["http://rightsstatements.org/vocab/InC/1.0/"]
             )).to eq("<a href=\"http://rightsstatements.org/vocab/InC/1.0/\">In Copyright</a>")
    end
  end

  describe "#human_readable_date" do
    it "ensures that the display of the date is human-readable" do
      expect(helper.human_readable_date(value: ["2016-08-15T00:00:00Z"])).to eq("08/15/2016")
    end
  end

  describe "#banner_image" do
    it "returns the configured Hyrax banner image" do
      expect(helper.banner_image).to eq(Hyrax.config.banner_image)
    end
  end

  describe "#collection_title_by_id" do
    let(:solr_doc) { double(id: "abcd12345") }
    let(:bad_solr_doc) { double(id: "efgh67890") }
    let(:solr_response) { double(docs: [solr_doc]) }
    let(:bad_solr_response) { double(docs: [bad_solr_doc]) }
    let(:empty_solr_response) { double(docs: []) }
    let(:repository) { double }

    before do
      allow(controller).to receive(:repository).and_return(repository)
      allow(solr_doc).to receive(:[]).with("title_tesim").and_return(["Collection of Awesomeness"])
      allow(bad_solr_doc).to receive(:[]).with("title_tesim").and_return(nil)
      allow(repository).to receive(:find).with("abcd12345").and_return(solr_response)
      allow(repository).to receive(:find).with("efgh67890").and_return(bad_solr_response)
      allow(repository).to receive(:find).with("bad-id").and_return(empty_solr_response)
    end

    it "returns the first title of the collection" do
      expect(helper.collection_title_by_id("abcd12345")).to eq "Collection of Awesomeness"
    end

    it "returns nil if collection doesn't have title_tesim field" do
      expect(helper.collection_title_by_id("efgh67890")).to eq nil
    end

    it "returns nil if collection not found" do
      expect(helper.collection_title_by_id("bad-id")).to eq nil
    end
  end

  describe "#thumbnail_label_for" do
    it "gives a string even if no thumbnail label can be found" do
      expect(helper.thumbnail_label_for(object: Object.new)).to be_a String
    end

    it 'interoperates with CollectionForm' do
      collection = ::Collection.new
      collection.thumbnail = ::FileSet.create(title: ["thumbnail"])

      form = Hyrax::Forms::CollectionForm.new(collection,
                                              :FAKE_ABILITY,
                                              :FAKE_BLACKLIGHT_REPOSITORY)

      expect(helper.thumbnail_label_for(object: form)).to eq 'thumbnail'
    end

    it 'interoperates with AdminSetForm' do
      admin_set = AdminSet.new
      admin_set.thumbnail = ::FileSet.create(title: ["thumbnail"])

      form = Hyrax::Forms::AdminSetForm.new(admin_set,
                                            :FAKE_ABILITY,
                                            :FAKE_BLACKLIGHT_REPOSITORY)

      expect(helper.thumbnail_label_for(object: form)).to eq 'thumbnail'
    end
  end
end
