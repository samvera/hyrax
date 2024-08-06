# frozen_string_literal: true
require 'hyrax/rubocop/custom_cops'

RSpec.describe Hyrax::RuboCop::CustomCops::ArResource do
  subject(:cop) { described_class.new }

  it 'is not allowed to include Hyrax::ArResource' do
    expect_offense(<<~RUBY)
      include Hyrax::ArResource
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not `include Hyrax::ArResource`.
    RUBY
  end

  it 'is not allowed to include ArResource' do
    expect_offense(<<~RUBY)
      include ArResource
      ^^^^^^^^^^^^^^^^^^ Do not `include Hyrax::ArResource`.
    RUBY
  end
end

# RSpec.describe Hyrax::RuboCop::CustomCops::AdditionalCustomCops  do; end
