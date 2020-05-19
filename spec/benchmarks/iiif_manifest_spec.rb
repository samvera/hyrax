# frozen_string_literal: true

require 'spec_helper'
require 'rspec-benchmark'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'IIIF Manifest generation performance', :benchmark do
  include RSpec::Benchmark::Matchers

  it 'generates manifests quickly (<15ms) for simple works' do
    work      = FactoryBot.create(:work)
    user      = FactoryBot.create(:admin)
    request   = double(host: 'example.org', base_url: 'http://example.org')
    presenter = Hyrax::WorkShowPresenter.new(work, Ability.new(user), request)

    expect { Hyrax::ManifestBuilderService.new.manifest_for(presenter: presenter) }
      .to perform_under(15).ms.warmup(2).times.sample(10).times
  end

  it 'generates manifests quickly (<25ms) for works with several children' do
    work      = FactoryBot.create(:work_with_file_and_work)
    user      = FactoryBot.create(:admin)
    request   = double(host: 'example.org', base_url: 'http://example.org')
    presenter = Hyrax::WorkShowPresenter.new(work, Ability.new(user), request)

    expect { Hyrax::ManifestBuilderService.new.manifest_for(presenter: presenter) }
      .to perform_under(25).ms.warmup(2).times.sample(10).times
  end

  it 'has constant performance for a large number of child works'
end
# rubocop:enable RSpec/DescribeClass
