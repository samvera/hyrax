require 'spec_helper'

describe SufiaHelper, type: :helper do
  describe "#link_to_facet_list" do
    def search_state_double(value)
      double('SearchState', add_facet_params_and_redirect: { f: { vehicle_type_sim: [value] } })
    end
    let(:search_state_for_car) { search_state_double("car") }
    let(:search_state_for_truck) { search_state_double("truck") }
    before do
      allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      allow(helper).to receive(:search_state).exactly(2).times.and_return(search_state_for_car, search_state_for_truck)
      allow(helper).to receive(:search_action_path) do |*args|
        search_catalog_path(*args)
      end
    end

    context "with values" do
      subject { helper.link_to_facet_list(['car', 'truck'], 'vehicle_type') }

      it "joins the values" do
        car_link = search_catalog_path(f: { 'vehicle_type_sim' => ['car'] })
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
    let(:document) { SolrDocument.new(active_fedora_model_ssi: 'Collection') }
    subject { helper.collection_thumbnail(document) }
    it { is_expected.to eq '<span class="glyphicon glyphicon-th collection-icon-search"></span>' }
  end

  describe "#link_to_telephone" do
    before do
      @user = mock_model(User)
      allow(@user).to receive(:telephone).and_return('867-5309')
    end

    context "when @user is set" do
      it "returns a link to the user's telephone" do
        expect(helper.link_to_telephone).to eq("<a href=\"wtai://wp/mc;867-5309\">867-5309</a>")
      end
    end

    context "when @user is not set" do
      it "returns a link to the user's telephone" do
        expect(helper.link_to_telephone(@user)).to eq("<a href=\"wtai://wp/mc;867-5309\">867-5309</a>")
      end
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

  describe '#zotero_label' do
    subject { helper }

    it { is_expected.to respond_to(:zotero_label) }
  end

  describe "#number_of_deposits" do
    let(:conn) { ActiveFedora::SolrService.instance.conn }
    let(:user1) { User.new(email: "abc@test") }
    let(:user2) { User.new(email: "abc@test.123") }
    before do
      create_models("Collection", user1, user2)
    end

    it "finds only 3 files" do
      expect(helper.number_of_deposits(user1)).to eq(3)
    end

    def create_models(model, user1, user2)
      # deposited by the first user
      3.times do |t|
        conn.add id: "199#{t}", Solrizer.solr_name('depositor', :stored_searchable) => user1.user_key, "has_model_ssim" => [model],
                 Solrizer.solr_name('depositor', :symbol) => user1.user_key
      end

      # deposited by the second user, but editable by the first
      conn.add id: "1994", Solrizer.solr_name('depositor', :stored_searchable) => user2.user_key, "has_model_ssim" => [model],
               Solrizer.solr_name('depositor', :symbol) => user2.user_key, "edit_access_person_ssim" => user1.user_key
      conn.commit
    end
  end

  describe "#iconify_auto_link" do
    subject { helper.iconify_auto_link('Foo < http://www.example.com. & More text') }
    it "escapes input" do
      expect(subject).to start_with('Foo &lt;')
      expect(subject).to end_with('. &amp; More text')
    end
    it "adds links" do
      expect(subject).to include('<a href="http://www.example.com">')
    end
    it "adds icons" do
      expect(subject).to include('class="glyphicon glyphicon-new-window"')
    end
  end
end
