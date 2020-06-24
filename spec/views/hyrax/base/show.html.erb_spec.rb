# frozen_string_literal: true
RSpec.describe 'hyrax/base/show.html.erb', type: :view do
  let(:work_solr_document) do
    SolrDocument.new(id: '999',
                     title_tesim: ['My Title'],
                     creator_tesim: ['Doe, John', 'Doe, Jane'],
                     date_modified_dtsi: '2011-04-01',
                     has_model_ssim: ['GenericWork'],
                     depositor_tesim: depositor.user_key,
                     description_tesim: ['Lorem ipsum lorem ipsum.'],
                     keyword_tesim: ['bacon', 'sausage', 'eggs'],
                     rights_statement_tesim: ['http://example.org/rs/1'],
                     rights_notes_tesim: ['Notes on the rights'],
                     date_created_tesim: ['1984-01-02'],
                     publisher_tesim: ['French Press'])
  end

  let(:file_set_solr_document) do
    SolrDocument.new(id: '123',
                     title_tesim: ['My FileSet'],
                     depositor_tesim: depositor.user_key)
  end

  let(:ability) { double }

  let(:presenter) do
    Hyrax::WorkShowPresenter.new(work_solr_document, ability, request)
  end

  let(:workflow_presenter) do
    double('workflow_presenter', badge: 'Foobar')
  end

  let(:representative_presenter) do
    Hyrax::FileSetPresenter.new(file_set_solr_document, ability)
  end

  let(:page) { Capybara::Node::Simple.new(rendered) }

  let(:request) { double('request', host: 'test.host') }

  let(:depositor) do
    stub_model(User,
               user_key: 'bob',
               twitter_handle: 'bot4lib')
  end

  before do
    allow(presenter).to receive(:workflow).and_return(workflow_presenter)
    allow(presenter).to receive(:representative_presenter).and_return(representative_presenter)
    allow(presenter).to receive(:representative_id).and_return(representative_presenter&.id)
    allow(presenter).to receive(:tweeter).and_return("@#{depositor.twitter_handle}")
    allow(presenter).to receive(:human_readable_type).and_return("Work")
    allow(controller).to receive(:current_user).and_return(depositor)
    allow(User).to receive(:find_by_user_key).and_return(depositor.user_key)
    allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
    allow(view).to receive(:signed_in?)
    allow(view).to receive(:on_the_dashboard?).and_return(false)
    stub_template 'hyrax/base/_metadata.html.erb' => ''
    stub_template 'hyrax/base/_relationships.html.erb' => ''
    stub_template 'hyrax/base/_show_actions.html.erb' => ''
    stub_template 'hyrax/base/_social_media.html.erb' => ''
    stub_template 'hyrax/base/_citations.html.erb' => ''
    stub_template 'hyrax/base/_items.html.erb' => ''
    stub_template 'hyrax/base/_workflow_actions_widget.html.erb' => ''
    stub_template '_masthead.html.erb' => ''
    assign(:presenter, presenter)
    render template: 'hyrax/base/show', layout: 'layouts/hyrax/1_column'
  end

  it 'shows workflow badge' do
    expect(page).to have_content 'Foobar'
  end

  describe 'IIIF viewer integration' do
    before do
      allow(presenter).to receive(:iiif_viewer?).and_return(viewer_enabled)
      render template: 'hyrax/base/show'
    end

    context 'when presenter says it is enabled' do
      let(:viewer_enabled) { true }

      it 'renders the UniversalViewer' do
        expect(page).to have_selector 'div.viewer-wrapper'
      end
    end

    context 'when presenter says it is disabled' do
      let(:viewer_enabled) { false }

      it 'omits the UniversalViewer' do
        expect(page).not_to have_selector 'div.viewer-wrapper'
      end
    end
  end

  describe 'head tag page title' do
    it 'appears in head tags' do
      head_tag = Nokogiri::HTML(rendered).xpath("//head/title")
      expect(head_tag.text).to eq("Work | My Title | ID: 999 | Hyrax")
    end
  end

  describe 'google scholar' do
    it 'appears in meta tags' do
      gscholar_meta_tags = Nokogiri::HTML(rendered).xpath("//meta[contains(@name, 'citation_')]")
      expect(gscholar_meta_tags.count).to eq(7)
    end

    it 'displays description' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='description']")
      expect(tag.attribute('content').value).to eq('Lorem ipsum lorem ipsum.')
    end

    it 'displays title' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_title']")
      expect(tag.attribute('content').value).to eq('My Title')
    end

    it 'displays authors' do
      tags = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_author']")
      expect(tags.first.attribute('content').value).to eq('Doe, John')
      expect(tags.last.attribute('content').value).to eq('Doe, Jane')
    end

    it 'displays publication date' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_publication_date']")
      expect(tag.attribute('content').value).to eq('1984-01-02')
    end

    it 'displays download URL' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_pdf_url']")
      expect(tag.attribute('content').value).to eq('http://test.host/downloads/123')
    end

    it 'displays keyword' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_keywords']")
      expect(tag.attribute('content').value).to eq('bacon; sausage; eggs')
    end

    it 'displays publisher' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_publisher']")
      expect(tag.attribute('content').value).to eq('French Press')
    end

    context 'with minimal record' do
      let(:work_solr_document) do
        SolrDocument.new(id: '999',
                         title_tesim: ['My Title'],
                         date_modified_dtsi: '2011-04-01',
                         has_model_ssim: ['GenericWork'],
                         depositor_tesim: depositor.user_key)
      end
      let(:representative_presenter) { nil }

      it 'appears in meta tags' do
        gscholar_meta_tags = Nokogiri::HTML(rendered).xpath("//meta[contains(@name, 'citation_')]")
        expect(gscholar_meta_tags.count).to eq(1)
      end

      it 'displays title as description' do
        tag = Nokogiri::HTML(rendered).xpath("//meta[@name='description']")
        expect(tag.attribute('content').value).to eq('My Title')
      end

      it 'displays title' do
        tag = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_title']")
        expect(tag.attribute('content').value).to eq('My Title')
      end

      it 'displays authors' do
        tags = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_author']")
        expect(tags).to be_blank
      end

      it 'displays publication date' do
        tag = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_publication_date']")
        expect(tag).to be_blank
      end

      it 'displays download URL' do
        tag = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_pdf_url']")
        expect(tag).to be_blank
      end

      it 'displays keyword' do
        tag = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_keywords']")
        expect(tag).to be_blank
      end

      it 'displays publisher' do
        tag = Nokogiri::HTML(rendered).xpath("//meta[@name='citation_publisher']")
        expect(tag).to be_blank
      end
    end
  end

  describe 'twitter cards' do
    it 'appears in meta tags' do
      twitter_meta_tags = Nokogiri::HTML(rendered).xpath("//meta[contains(@name, 'twitter:') or contains(@property, 'og:')]")
      expect(twitter_meta_tags.count).to eq(13)
    end

    it 'displays twitter:card' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:card']")
      expect(tag.attribute('content').value).to eq('product')
    end

    it 'displays twitter:site' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:site']")
      expect(tag.attribute('content').value).to eq('@SamveraRepo')
    end

    it 'displays twitter:creator' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:creator']")
      expect(tag.attribute('content').value).to eq('@bot4lib')
    end

    it 'displays og:site_name' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:site_name']")
      expect(tag.attribute('content').value).to eq('Hyrax')
    end

    it 'displays og:type' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:type']")
      expect(tag.attribute('content').value).to eq('object')
    end

    it 'displays og:title' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:title']")
      expect(tag.attribute('content').value).to eq('My Title')
    end

    it 'displays og:description' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:description']")
      expect(tag.attribute('content').value).to eq('Lorem ipsum lorem ipsum.')
    end

    it 'displays og:image' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:image']")
      expect(tag.attribute('content').value).to eq('http://test.host/downloads/123')
    end

    it 'displays og:url' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:url']")
      expect(tag.attribute('content').value).to eq('http://test.host/concern/generic_works/999')
    end

    it 'displays twitter:data1' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:data1']")
      expect(tag.attribute('content').value).to eq('bacon, sausage, eggs')
    end

    it 'displays twitter:label1' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:label1']")
      expect(tag.attribute('content').value).to eq('Keywords')
    end

    it 'displays twitter:data2' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:data2']")
      expect(tag.attribute('content').value).to eq('http://example.org/rs/1')
    end

    it 'displays twitter:label2' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:label2']")
      expect(tag.attribute('content').value).to eq('Rights Statement')
    end
  end
end
