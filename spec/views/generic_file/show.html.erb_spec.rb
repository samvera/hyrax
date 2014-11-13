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
    stub_model(GenericFile, id: '123', noid: '123',
      depositor: depositor.user_key,
      audit_stat: 1,
      title: ['My Title'],
      description: ['Lorem ipsum lorem ipsum.'],
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

  before do
    allow(generic_file).to receive(:content).and_return(content)
    allow(controller).to receive(:current_user).and_return(depositor)
    allow_any_instance_of(Ability).to receive(:can?).and_return(true)
    allow(User).to receive(:find_by_user_key).with(generic_file.depositor).and_return(depositor)
    allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
    allow(view).to receive(:on_the_dashboard?).and_return(false)
    assign(:generic_file, generic_file)
    assign(:events, [])
    assign(:notify_number, 0)
  end

  describe 'schema.org' do
    describe 'descriptive metadata' do
      before do
        render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
        @item = Mida::Document.new(rendered).items.first
      end

      it 'sets itemtype to CreativeWork' do
        expect(@item.type).to eq('http://schema.org/CreativeWork')
      end

      it 'sets title as name' do
        expect(@item.properties['name'].first).to eq('My Title')
      end

      it 'sets description' do
        expect(@item.properties['description'].first).to eq('Lorem ipsum lorem ipsum.')
      end

      it 'sets tag as keywords' do
        expect(@item.properties['keywords']).to include('bacon', 'sausage', 'eggs')
      end

      it 'sets based_near as contentLocation' do
        based_near = @item.properties['contentLocation'].first
        expect(based_near.type).to eq('http://schema.org/Place')
        expect(based_near.properties['name'].first).to eq('Seattle, WA, US')
      end

      it 'sets contributor' do
        contributors = @item.properties['contributor']
        expect(contributors.count).to eq(2)
        contributor = contributors.first
        expect(contributor.type).to eq('http://schema.org/Person')
        expect(contributor.properties['name'].first).to eq('Tweedledee')
      end

      it 'sets creator' do
        creators = @item.properties['creator']
        expect(creators.count).to eq(2)
        creator = creators.first
        expect(creator.type).to eq('http://schema.org/Person')
        expect(creator.properties['name'].first).to eq('Doe, John')
      end

      it 'sets date_created as dateCreated' do
        expect(@item.properties['dateCreated'].first).to eq('1984-01-02')
      end

      it 'sets language as inLanguage' do
        expect(@item.properties['inLanguage'].first).to eq('Quechua')
      end

      it 'sets publisher' do
        publisher = @item.properties['publisher'].first
        expect(publisher.type).to eq('http://schema.org/Organization')
        expect(publisher.properties['name'].first).to eq('Random Publishing, Inc.')
      end

      it 'sets subjects' do
        subjects = @item.properties['about']
        expect(subjects.count).to eq(3)
        subject = subjects.first
        expect(subject.type).to eq('http://schema.org/Thing')
        expect(subject.properties['name'].first).to eq('Biology')
      end

      it 'sets depositor as accountablePerson' do
        depositor = @item.properties['accountablePerson'].first
        expect(depositor.type).to eq('http://schema.org/Person')
        expect(depositor.properties['name'].first).to eq('bob')
      end
    end

    describe 'resource type-specific itemtypes' do
      context 'when resource_type is Audio' do
        it 'sets itemtype to AudioObject' do
          generic_file.resource_type = ['Audio']
          render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
          @item = Mida::Document.new(rendered).items.first
          expect(@item.type).to eq('http://schema.org/AudioObject')
        end
      end
      context 'when resource_type is Conference Proceeding' do
        it 'sets itemtype to ScholarlyArticle' do
          generic_file.resource_type = ['Conference Proceeding']
          render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
          @item = Mida::Document.new(rendered).items.first
          expect(@item.type).to eq('http://schema.org/ScholarlyArticle')
        end
      end
    end
  end

  describe 'google scholar' do
    # NOTE: before(:all) will not work in this context
    before(:each) do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
    end

    it 'appears in meta tags' do
      gscholar_meta_tags = Nokogiri::HTML(rendered).xpath("//meta[contains(@name, 'citation_')]")
      expect(gscholar_meta_tags.count).to eq(5)
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
  end

  describe 'twitter cards' do
    # NOTE: before(:all) will not work in this context
    before(:each) do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
    end

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
      expect(tag.attribute('content').value).to eq('@HydraSphere')
    end

    it 'displays twitter:creator' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:creator']")
      expect(tag.attribute('content').value).to eq('@bot4lib')
    end

    it 'displays og:site_name' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:site_name']")
      expect(tag.attribute('content').value).to eq('Sufia')
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
      expect(tag.attribute('content').value).to eq('http://test.host/downloads/123?datastream_id=thumbnail')
    end

    it 'displays og:url' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:url']")
      expect(tag.attribute('content').value).to eq('http://test.host/files/123')
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
      expect(tag.attribute('content').value).to eq('http://example.org/rights/1')
    end

    it 'displays twitter:label2' do
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:label2']")
      expect(tag.attribute('content').value).to eq('Rights')
    end
  end

  describe 'analytics' do
    context 'when enabled' do
      before do
        Sufia.config.analytics = true
      end

      it 'appears on page' do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_selector('a#stats', count: 1)
      end
    end

    context 'when disabled' do
      before do
        Sufia.config.analytics = false
      end

      it 'does not appear on page' do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_no_selector('a#stats')
      end
    end
  end

  describe 'featured' do
    context "public file" do
      before do
        allow(generic_file).to receive(:public?).and_return(true)
      end

      it "shows featured feature link for public file" do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_selector('a[data-behavior="feature"]', count: 1)
      end
    end

    context "non public file" do
      before do
        allow(generic_file).to receive(:public?).and_return(false)
      end

      it "does not show feature link for non public file" do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_no_selector('a[data-behavior="feature"]', count: 1)
      end
    end
  end

  describe 'collections list' do
    context "when the file is not featured in any collections" do

      it "should display the empty message" do
        render
        expect(rendered).to have_text(t('sufia.file.collections_list.empty'))
      end
    end

    context "when the file is featured in collections" do
      let(:collection1) {
        stub_model(Collection,
          title: 'collection1',
          noid: '456')
      }
 
      before do
        allow(generic_file).to receive(:collections).and_return([collection1])
      end

      it "should display the header and titles of collections it belongs to" do
        render
        expect(rendered).to have_text(t('sufia.file.collections_list.heading'))
        expect(rendered).to have_text('collection1')
      end
    end
  end

  describe 'visibility' do
    let(:expected) do
      '<span class="label label-danger" title="'+t('sufia.visibility.private')+'">'+t('sufia.visibility.private')+'</span></a>' 
    end
    it "should display the visibility badge" do
      render
      expect(rendered).to include(expected)
    end
  end

end
