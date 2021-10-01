# frozen_string_literal: true

RSpec.shared_examples 'a model with basic metadata' do
  subject(:resource) { described_class.new }

  it 'has abstracts' do
    expect { resource.abstract = ['lorem ipsum', 'a story about moomins'] }
      .to change { resource.abstract }
      .to contain_exactly 'lorem ipsum', 'a story about moomins'
  end

  it 'has a label' do
    expect { resource.label = 'one single label' }
      .to change { resource.label }
      .to eq 'one single label'
  end

  it 'has language' do
    expect { resource.language = ['en', 'fi'] }
      .to change { resource.language }
      .to contain_exactly 'en', 'fi'
  end

  it 'has licenses' do
    expect { resource.license = ['http://example.com/li1', 'http://example.com/li2'] }
      .to change { resource.license }
      .to contain_exactly 'http://example.com/li1', 'http://example.com/li2'
  end

  it 'has a relative path' do
    expect { resource.relative_path = 'hamburger' }
      .to change { resource.relative_path }
      .to eq 'hamburger'
  end

  it 'has resource types' do
    expect { resource.resource_type = ['book', 'image'] }
      .to change { resource.resource_type }
      .to contain_exactly 'book', 'image'
  end

  it 'has rights notes' do
    expect { resource.rights_notes = ['secret', 'do not use'] }
      .to change { resource.rights_notes }
      .to contain_exactly 'secret', 'do not use'
  end

  it 'has rights statements' do
    expect { resource.rights_statement = ['http://example.com/rs1', 'http://example.com/rs2'] }
      .to change { resource.rights_statement }
      .to contain_exactly 'http://example.com/rs1', 'http://example.com/rs2'
  end

  it 'has sources' do
    expect { resource.source = ['first', 'second'] }
      .to change { resource.source }
      .to contain_exactly 'first', 'second'
  end

  it 'has subjects' do
    expect { resource.subject = ['moomin', 'snork'] }
      .to change { resource.subject }
      .to contain_exactly 'moomin', 'snork'
  end
end

RSpec.shared_examples 'a model with core metadata' do
  subject(:resource) { described_class.new }
  let(:date)         { Time.zone.today }

  it 'has a date_modified' do
    expect { resource.date_modified = date }
      .to change { resource.date_modified }
      .to eq date
  end

  it 'has a date_uploaded' do
    expect { resource.date_uploaded = date }
      .to change { resource.date_uploaded }
      .to eq date
  end

  it 'has a depositor' do
    expect { resource.depositor = 'userid' }
      .to change { resource.depositor }
      .to eq 'userid'
  end

  it 'has a title' do
    expect { resource.title = ['title'] }
      .to change { resource.title }
      .to contain_exactly('title')
  end
end

RSpec.shared_examples 'a model with collection basic metadata' do
  subject(:resource) { described_class.new }
  let(:date)         { Time.zone.today }

  # from core metadata included in collection basic metadata
  it 'has a date_modified' do
    expect { resource.date_modified = date }
      .to change { resource.date_modified }
            .to eq date
  end

  # from core metadata included in collection basic metadata
  it 'has a date_uploaded' do
    expect { resource.date_uploaded = date }
      .to change { resource.date_uploaded }
            .to eq date
  end

  # from core metadata included in collection basic metadata
  it 'has a depositor' do
    expect { resource.depositor = 'userid' }
      .to change { resource.depositor }
            .to eq 'userid'
  end

  # from core metadata included in collection basic metadata
  # with multiple title override
  it 'has a title' do
    expect { resource.title = ['title', 'title 2'] }
      .to change { resource.title }
            .to contain_exactly 'title', 'title 2'
  end

  it 'description' do
    expect { resource.description = ['lorem ipsum', 'another description'] }
      .to change { resource.description }
            .to contain_exactly 'lorem ipsum', 'another description'
  end

  it 'has alternative title' do
    expect { resource.alternative_title = ['lorem ipsum', 'a story about moomins'] }
      .to change { resource.alternative_title }
            .to contain_exactly 'lorem ipsum', 'a story about moomins'
  end

  it 'has a creator' do
    expect { resource.creator = ['Creator, Joe', 'Creator, Jane'] }
      .to change { resource.creator }
            .to contain_exactly 'Creator, Joe', 'Creator, Jane'
  end

  it 'has licenses' do
    expect { resource.license = ['http://example.com/li1', 'http://example.com/li2'] }
      .to change { resource.license }
            .to contain_exactly 'http://example.com/li1', 'http://example.com/li2'
  end

  it 'has subjects' do
    expect { resource.subject = ['moomin', 'snork'] }
      .to change { resource.subject }
            .to contain_exactly 'moomin', 'snork'
  end

  it 'has language' do
    expect { resource.language = ['en', 'fi'] }
      .to change { resource.language }
            .to contain_exactly 'en', 'fi'
  end

  it 'has based near' do
    expect { resource.based_near = ['Ithaca (US)', 'New York (US)'] }
      .to change { resource.based_near }
            .to contain_exactly 'Ithaca (US)', 'New York (US)'
  end

  it 'has a related url' do
    expect { resource.related_url = ['http://example.com/info', 'http://example.com/contact'] }
      .to change { resource.related_url }
            .to contain_exactly 'http://example.com/info', 'http://example.com/contact'
  end

  it 'has resource types' do
    expect { resource.resource_type = ['book', 'image'] }
      .to change { resource.resource_type }
            .to contain_exactly 'book', 'image'
  end
end
