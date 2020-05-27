# frozen_string_literal: true

require 'spec_helper'
require 'rspec-benchmark'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'IIIF Manifest generation performance', :benchmark do
  include RSpec::Benchmark::Matchers

  it 'generates manifests quickly (<8ms) for simple works' do
    work      = FactoryBot.create(:work)
    presenter = Hyrax::IiifManifestPresenter.new(work)

    expect { Hyrax::ManifestBuilderService.new.manifest_for(presenter: presenter) }
      .to perform_under(8).ms.warmup(2).times.sample(10).times
  end

  it 'generates manifests quickly (<10ms) for works with several children' do
    work      = FactoryBot.create(:work_with_image_files)
    presenter = Hyrax::IiifManifestPresenter.new(work)

    expect { Hyrax::ManifestBuilderService.new.manifest_for(presenter: presenter) }
      .to perform_under(10).ms.warmup(2).times.sample(10).times
  end

  it 'has constant performance for a large number of child works'
end
# rubocop:enable RSpec/DescribeClass
