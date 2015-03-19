require 'spec_helper'

describe 'generic_files/show.html.erb', :type => :view do
  let(:depositor) {
    stub_model(User,
      user_key: 'bob',
      twitter_handle: 'bot4lib')
  }

  let(:content) do
    content = double('content', versions: [], mimeType: 'application/pdf')
  end

  let(:generic_file) do
    stub_model(GenericFile, id: '123',
      depositor: depositor.user_key,
      audit_stat: 1,
      title: ['My Title'],
      description: ['Lorem ipsum lorem ipsum. http://my.link.com'],
      tag: ['bacon', 'sausage', 'eggs'],
      rights: ['http://example.org/rights/1'],
      based_near: ['Seattle, WA, US'],
      contributor: ['Tweedledee', 'Tweedledum'],
      creator: ['Doe, John', 'Doe, Jane'],
      date_created: ['1984-01-02'],
      language: ['Quechua'],
      publisher: ['Random Publishing, Inc.'],
      subject: ['Biology', 'Physiology', 'Ethnography'])
  end

  let(:presenter) do
    Sufia::GenericFilePresenter.new(generic_file)
  end

  before do
    allow(generic_file).to receive(:content).and_return(content)
    allow(controller).to receive(:current_user).and_return(depositor)
    allow_any_instance_of(Ability).to receive(:can?).and_return(true)
    allow(User).to receive(:find_by_user_key).with(generic_file.depositor).and_return(depositor)
    allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
    allow(view).to receive(:on_the_dashboard?).and_return(false)
    assign(:generic_file, generic_file)
    assign(:presenter, presenter)
    assign(:events, [])
    assign(:notify_number, 0)
  end

  describe 'title heading' do
    before do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
    end
    let(:doc) { Nokogiri::HTML(rendered) }

    it 'shows the first title' do
      h1 = doc.xpath("//h1[@class='visibility']").text
      expect(h1).to start_with 'My Title'
    end

    it 'shows the description' do
      d1 = doc.xpath("//p[@class='genericfile_description']").text
      expect(d1).to start_with 'Lorem ipsum'
    end

    it 'shows links in the description' do
      a1 = doc.xpath("//p[@class='genericfile_description']/a").text
      expect(a1).to start_with 'http://my.link.com'
    end
  end

  describe 'schema.org' do
    let(:item) { Mida::Document.new(rendered).items.first }
    describe 'descriptive metadata' do
      before do
        render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      end

      it 'draws schema.org fields' do
        # set itemtype to CreativeWork
        expect(item.type).to eq('http://schema.org/CreativeWork')

        # tag as keywords
        expect(item.properties['keywords']).to include('bacon', 'sausage', 'eggs')

        # based_near as contentLocation
        based_near = item.properties['contentLocation'].first
        expect(based_near.type).to eq('http://schema.org/Place')
        expect(based_near.properties['name'].first).to eq('Seattle, WA, US')

        contributors = item.properties['contributor']
        expect(contributors.count).to eq(2)
        contributor = contributors.first
        expect(contributor.type).to eq('http://schema.org/Person')
        expect(contributor.properties['name'].first).to eq('Tweedledee')

        creators = item.properties['creator']
        expect(creators.count).to eq(2)
        creator = creators.first
        expect(creator.type).to eq('http://schema.org/Person')
        expect(creator.properties['name'].first).to eq('Doe, John')

        expect(item.properties['dateCreated'].first).to eq('1984-01-02')

        expect(item.properties['inLanguage'].first).to eq('Quechua')

        publisher = item.properties['publisher'].first
        expect(publisher.type).to eq('http://schema.org/Organization')
        expect(publisher.properties['name'].first).to eq('Random Publishing, Inc.')

        subjects = item.properties['about']
        expect(subjects.count).to eq(3)
        subject = subjects.first
        expect(subject.type).to eq('http://schema.org/Thing')
        expect(subject.properties['name'].first).to eq('Biology')

        depositor = item.properties['accountablePerson'].first
        expect(depositor.type).to eq('http://schema.org/Person')
        expect(depositor.properties['name'].first).to eq('bob')
      end
    end
  end

  describe 'google scholar' do
    before do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
    end
    let(:doc) { Nokogiri::HTML(rendered) }

    it 'displays meta tags' do
      gscholar_meta_tags = doc.xpath("//meta[contains(@name, 'citation_')]")
      expect(gscholar_meta_tags.count).to eq(5)

      tag = doc.xpath("//meta[@name='citation_title']")
      expect(tag.attribute('content').value).to eq('My Title')

      tags = doc.xpath("//meta[@name='citation_author']")
      expect(tags.first.attribute('content').value).to eq('Doe, John')
      expect(tags.last.attribute('content').value).to eq('Doe, Jane')

      tag = doc.xpath("//meta[@name='citation_publication_date']")
      expect(tag.attribute('content').value).to eq('1984-01-02')

      tag = doc.xpath("//meta[@name='citation_pdf_url']")
      expect(tag.attribute('content').value).to eq('http://test.host/downloads/123')
    end
  end

  describe 'twitter cards' do
    before do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
    end
    let(:doc) { Nokogiri::HTML(rendered) }

    it 'appears in meta tags' do
      twitter_meta_tags = doc.xpath("//meta[contains(@name, 'twitter:') or contains(@property, 'og:')]")
      expect(twitter_meta_tags.count).to eq(13)

      tag = doc.xpath("//meta[@name='twitter:card']")
      expect(tag.attribute('content').value).to eq('product')

      tag = doc.xpath("//meta[@name='twitter:site']")
      expect(tag.attribute('content').value).to eq('@HydraSphere')

      tag = doc.xpath("//meta[@name='twitter:creator']")
      expect(tag.attribute('content').value).to eq('@bot4lib')

      tag = doc.xpath("//meta[@property='og:site_name']")
      expect(tag.attribute('content').value).to eq('Sufia')

      tag = doc.xpath("//meta[@property='og:type']")
      expect(tag.attribute('content').value).to eq('object')

      tag = doc.xpath("//meta[@property='og:title']")
      expect(tag.attribute('content').value).to eq('My Title')

      tag = doc.xpath("//meta[@property='og:description']")
      expect(tag.attribute('content').value).to eq('Lorem ipsum lorem ipsum. http://my.link.com')

      tag = doc.xpath("//meta[@property='og:image']")
      expect(tag.attribute('content').value).to eq('http://test.host/downloads/123?file=thumbnail')

      tag = doc.xpath("//meta[@property='og:url']")
      expect(tag.attribute('content').value).to eq('http://test.host/files/123')

      tag = doc.xpath("//meta[@name='twitter:data1']")
      expect(tag.attribute('content').value).to eq('bacon, sausage, eggs')

      tag = doc.xpath("//meta[@name='twitter:label1']")
      expect(tag.attribute('content').value).to eq('Keywords')

      tag = doc.xpath("//meta[@name='twitter:data2']")
      expect(tag.attribute('content').value).to eq('http://example.org/rights/1')

      tag = doc.xpath("//meta[@name='twitter:label2']")
      expect(tag.attribute('content').value).to eq('Rights')
    end
  end

  describe 'analytics' do
    let(:page) { Capybara::Node::Simple.new(rendered) }
    before do
      Sufia.config.analytics = analytics
      render
    end
    context 'when enabled' do
      let(:analytics) { true }

      it 'appears on page' do
        expect(page).to have_selector('a#stats', count: 1)
      end
    end

    context 'when disabled' do
      let(:analytics) { false }

      it 'does not appear on page' do
        expect(page).to have_no_selector('a#stats')
      end
    end
  end

  describe 'featured' do
    before do
      allow(generic_file).to receive(:public?).and_return(public)
      render
    end
    let(:page) { Capybara::Node::Simple.new(rendered) }

    context "public file" do
      let(:public) { true }

      it "shows featured feature link for public file" do
        expect(page).to have_selector('a[data-behavior="feature"]', count: 1)
      end
    end

    context "non public file" do
      let(:public) { false }

      it "does not show feature link for non public file" do
        expect(page).to have_no_selector('a[data-behavior="feature"]', count: 1)
      end
    end
  end

  describe 'collections list' do
    before do
      allow(generic_file).to receive(:collections).and_return(collections)
      render
    end

    context "when the file is not featured in any collections" do
      let(:collections) { [] }
      it "should display the empty message" do
        expect(rendered).to have_text(t('sufia.file.collections_list.empty'))
      end
    end

    context "when the file is featured in collections" do
      let(:collections) { [stub_model(Collection, title: 'collection1', id: '456') ] }

      it "should display the header and titles of collections it belongs to" do
        expect(rendered).to have_text(t('sufia.file.collections_list.heading'))
        expect(rendered).to have_text('collection1')
      end
    end
  end

  describe 'visibility' do
    before do
      render
    end
    it "should display the visibility badge" do
      expect(rendered).to include('<span class="label label-danger" title="'+t('sufia.visibility.private_title_attr')+'">'+t('sufia.visibility.private')+'</span></a>')
    end
  end

end
