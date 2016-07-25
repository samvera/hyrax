RSpec.describe Sufia::UserStatImporter do
  it 'can be instantiated without throwing an error.' do
    expect { described_class.new(verbose: true, logging: true) }.not_to raise_error(StandardError)
  end
end
