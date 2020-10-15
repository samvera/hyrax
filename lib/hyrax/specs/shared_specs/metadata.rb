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
