require 'spec_helper'
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::FileSetDerivativesService do
  let(:file_set) { ::FileSet.new }
  subject { described_class.new(file_set) }
  it_behaves_like "a Hyrax::DerivativeService"
end
