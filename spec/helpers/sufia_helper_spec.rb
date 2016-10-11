def new_state
  Blacklight::SearchState.new({}, CatalogController.blacklight_config)
end

describe SufiaHelper, type: :helper do
  describe "show_transfer_request_title" do
    let(:sender) { create(:user) }
    let(:user) { create(:user) }
    let(:work) do
      GenericWork.create!(title: ["Test work"]) do |work|
        work.apply_depositor_metadata(sender.user_key)
      end
    end

    context "when work is canceled" do
      let(:request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: user, sending_user: sender, status: 'canceled') }
      subject { helper.show_transfer_request_title request }
      it { expect(subject).to eq 'Test work' }
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
          expect(subject).to be_a ActiveSupport::SafeBuffer
          expect(subject).to be_html_safe
        end
      end

      context "without values" do
        subject { helper.link_to_facet_list([], 'vehicle_type') }
        it "shows the default text" do
          expect(subject).to eq "No value entered"
          expect(subject).to be_a ActiveSupport::SafeBuffer
          expect(subject).to be_html_safe
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

  describe "has_collection_search_parameters?" do
    subject { helper }
    context "when cq is set" do
      before { allow(helper).to receive(:params).and_return(cq: 'foo') }
      it { is_expected.to have_collection_search_parameters }
    end
    context "when cq is not set" do
      before { allow(helper).to receive(:params).and_return(cq: '') }
      it { is_expected.not_to have_collection_search_parameters }
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
        allow(helper).to receive(:params).and_return(controller: "dashboard", q: "foo")
        expect(helper.current_search_parameters).to be_nil
      end

      it "is ignored on dashboard works, collections, highlights and shares" do
        allow(helper).to receive(:params).and_return(controller: "my/works", q: "foo")
        expect(helper.current_search_parameters).to be_nil
        allow(helper).to receive(:params).and_return(controller: "my/collections", q: "foo")
        expect(helper.current_search_parameters).to be_nil
        allow(helper).to receive(:params).and_return(controller: "my/highlights", q: "foo")
        expect(helper.current_search_parameters).to be_nil
        allow(helper).to receive(:params).and_return(controller: "my/shares", q: "foo")
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
        allow(helper).to receive(:params).and_return(controller: "dashboard")
        expect(helper.search_form_action).to eq(sufia.dashboard_works_path)
      end
    end

    context "when the user is on the my works page" do
      it "returns the my dashboard works path" do
        allow(helper).to receive(:params).and_return(controller: "my/works")
        expect(helper.search_form_action).to eq(sufia.dashboard_works_path)
      end
    end

    context "when the user is on the my collections page" do
      it "returns the my dashboard collections path" do
        allow(helper).to receive(:params).and_return(controller: "my/collections")
        expect(helper.search_form_action).to eq(sufia.dashboard_collections_path)
      end
    end

    context "when the user is on the my highlights page" do
      it "returns the my dashboard highlights path" do
        allow(helper).to receive(:params).and_return(controller: "my/highlights")
        expect(helper.search_form_action).to eq(sufia.dashboard_highlights_path)
      end
    end

    context "when the user is on the my shares page" do
      it "returns the my dashboard shares path" do
        allow(helper).to receive(:params).and_return(controller: "my/shares")
        expect(helper.search_form_action).to eq(sufia.dashboard_shares_path)
      end
    end
  end

  describe '#browser_supports_directory_upload?' do
    subject { helper.browser_supports_directory_upload? }
    context 'with Chrome' do
      before { controller.request.env['HTTP_USER_AGENT'] = 'Chrome' }
      it { is_expected.to be true }
    end
    context 'with a non-chrome browser' do
      before { controller.request.env['HTTP_USER_AGENT'] = 'Firefox' }
      it { is_expected.to be false }
    end
  end

  describe '#zotero_label' do
    subject { helper }
    it { is_expected.to respond_to(:zotero_label) }
  end

  describe "#iconify_auto_link" do
    let(:text)              { 'Foo < http://www.example.com. & More text' }
    let(:linked_text)       { 'Foo &lt; <a href="http://www.example.com"><span class="glyphicon glyphicon-new-window"></span> http://www.example.com</a>. &amp; More text' }
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
        expect(subject).to include('class="glyphicon glyphicon-new-window"')
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

  describe "#rights_statement_links" do
    let(:options) { instance_double(Hash) }
    it "calls license_links" do
      expect(Deprecation).to receive(:warn)
      expect(helper).to receive(:license_links).with(options)
      helper.rights_statement_links(options)
    end
  end

  describe "#license_links" do
    it "maps the url to a link with a label" do
      expect(helper.license_links(
               value: ["http://creativecommons.org/publicdomain/zero/1.0/"]
      )).to eq("<a href=\"http://creativecommons.org/publicdomain/zero/1.0/\">CC0 1.0 Universal</a>")
    end

    it "converts multiple rights statements to a sentence" do
      expect(helper.license_links(
               value: ["http://creativecommons.org/publicdomain/zero/1.0/",
                       "http://creativecommons.org/publicdomain/mark/1.0/",
                       "http://www.europeana.eu/portal/rights/rr-r.html"]
      )).to eq("<a href=\"http://creativecommons.org/publicdomain/zero/1.0/\">CC0 1.0 Universal</a>, <a href=\"http://creativecommons.org/publicdomain/mark/1.0/\">Public Domain Mark 1.0</a>, and <a href=\"http://www.europeana.eu/portal/rights/rr-r.html\">All rights reserved</a>")
    end
  end

  describe "#human_readable_date" do
    it "ensures that the display of the date is human-readable" do
      expect(helper.human_readable_date(value: ["2016-08-15T00:00:00Z"])).to eq("08/15/2016")
    end
  end
end
