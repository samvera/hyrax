# frozen_string_literal: true

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
