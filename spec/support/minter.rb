RSpec.configure do |config|
  # Switch to the File based minter, so we don't need to recreate the
  # database rows for the default minter.
  config.before(:suite) do
    ActiveFedora::Noid.configure do |noid_config|
      noid_config.minter_class = ActiveFedora::Noid::Minter::File
    end
  end
end
