require 'hydra/head'
require 'hydra/works'

module CurationConcerns
  module Collections
    extend ActiveSupport::Autoload
    autoload :SearchService
    autoload :AcceptsBatches
  end
end
