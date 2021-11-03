# frozen_string_literal: true
RSpec.describe BlacklightHelper, type: :helper do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:attributes) do
    { 'creator_tesim' => ['Justin', 'Joe'],
      'depositor_tesim' => ['jcoyne@justincoyne.com'],
      'proxy_depositor_ssim' => ['atz@stanford.edu'],
      'description_tesim' => ['This links to http://example.com/ What about that?'],
      'date_uploaded_dtsi' => '2013-03-14T00:00:00Z',
      'license_tesim' => ["http://creativecommons.org/publicdomain/zero/1.0/",
                          "http://creativecommons.org/publicdomain/mark/1.0/",
                          "http://www.europeana.eu/portal/rights/rr-r.html"],
      'rights_statement_tesim' => ['http://rightsstatements.org/vocab/InC/1.0/'],
      'identifier_tesim' => ['65434567654345654'],
      'keyword_tesim' => ['taco', 'mustache'],
      'subject_tesim' => ['Awesome'],
      'contributor_tesim' => ['Bird, Big'],
      'publisher_tesim' => ['Penguin Random House'],
      'based_near_label_tesim' => ['Pennsylvania'],
      'language_tesim' => ['English'],
      'resource_type_tesim' => ['Capstone Project'] }
  end

  let(:document) { SolrDocument.new(attributes) }

  before do
    allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
    allow(controller).to receive(:action_name).and_return('index')
  end

  describe "render_index_field_value" do
    include HyraxHelper # FIXME: isolate testing BlacklightHelper, not HyraxHelper. Also, this method is odd.
    def search_action_path(stuff)
      search_catalog_path(stuff)
    end

    let(:presenter) { index_presenter(document) }
    let(:field) { blacklight_config.index_fields.fetch(field_name) }
    subject { presenter.field_value field }

    context "description_tesim" do
      let(:field_name) { 'description_tesim' }

      it do
        is_expected.to eq 'This links to ' \
                          '<a href="http://example.com/"><span class="glyphicon glyphicon-new-window"></span>' \
                          ' http://example.com/</a> What about that?'
      end
    end

    context "license_tesim" do
      let(:field_name) { 'license_tesim' }

      it do
        is_expected.to eq "<a href=\"http://creativecommons.org/publicdomain/zero/1.0/\">Creative Commons CC0 1.0 Universal</a>, " \
                             "<a href=\"http://creativecommons.org/publicdomain/mark/1.0/\">Creative Commons Public Domain Mark 1.0</a>, " \
                             "and <a href=\"http://www.europeana.eu/portal/rights/rr-r.html\">All rights reserved</a>"
      end
    end

    context "rights_statement_tesim" do
      let(:field_name) { 'rights_statement_tesim' }

      it do
        is_expected.to eq "<a href=\"http://rightsstatements.org/vocab/InC/1.0/\">In Copyright</a>"
      end
    end

    context "metadata index links" do
      let(:search_state) { Hyrax::SearchState.new(params, blacklight_config, controller) }

      before do
        allow(controller).to receive(:search_state).and_return(search_state)
      end

      context "keyword_tesim" do
        let(:field_name) { 'keyword_tesim' }

        it do
          is_expected.to eq '<span itemprop="keywords">' \
                               '<a href="/catalog?f%5Bkeyword_sim%5D%5B%5D=taco">taco</a></span> and ' \
                               '<span itemprop="keywords"><a href="/catalog?f%5Bkeyword_sim%5D%5B%5D=mustache">mustache</a></span>'
        end
      end

      context "subject_tesim" do
        let(:field_name) { 'subject_tesim' }

        it { is_expected.to eq '<span itemprop="about"><a href="/catalog?f%5Bsubject_sim%5D%5B%5D=Awesome">Awesome</a></span>' }
      end

      context "creator_tesim" do
        let(:field_name) { 'creator_tesim' }

        it do
          is_expected.to eq '<span itemprop="creator">' \
                               '<a href="/catalog?f%5Bcreator_sim%5D%5B%5D=Justin">Justin</a></span> and ' \
                               '<span itemprop="creator"><a href="/catalog?f%5Bcreator_sim%5D%5B%5D=Joe">Joe</a></span>'
        end
      end

      context "contributor_tesim" do
        let(:field_name) { 'contributor_tesim' }

        it { is_expected.to eq '<span itemprop="contributor"><a href="/catalog?f%5Bcontributor_sim%5D%5B%5D=Bird%2C+Big">Bird, Big</a></span>' }
      end

      context "publisher_tesim" do
        let(:field_name) { 'publisher_tesim' }

        it { is_expected.to eq '<span itemprop="publisher"><a href="/catalog?f%5Bpublisher_sim%5D%5B%5D=Penguin+Random+House">Penguin Random House</a></span>' }
      end

      context "based_near_label_tesim" do
        let(:field_name) { 'based_near_label_tesim' }

        it { is_expected.to eq '<span itemprop="contentLocation"><a href="/catalog?f%5Bbased_near_label_sim%5D%5B%5D=Pennsylvania">Pennsylvania</a></span>' }
      end

      context "language_tesim" do
        let(:field_name) { 'language_tesim' }

        it { is_expected.to eq '<span itemprop="inLanguage"><a href="/catalog?f%5Blanguage_sim%5D%5B%5D=English">English</a></span>' }
      end

      context "resource_type_tesim" do
        let(:field_name) { 'resource_type_tesim' }

        it { is_expected.to eq '<a href="/catalog?f%5Bresource_type_sim%5D%5B%5D=Capstone+Project">Capstone Project</a>' }
      end

      context "identifier_tesim" do
        let(:field_name) { 'identifier_tesim' }

        it { is_expected.to eq '<a href="/catalog?q=%2265434567654345654%22&amp;search_field=identifier">65434567654345654</a>' }
      end
    end
  end
end
