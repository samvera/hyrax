# frozen_string_literal: true
module Hyrax
  module Permissions
    extend ActiveSupport::Autoload
    extend ActiveSupport::Concern
    autoload :Writable
    autoload :Readable

    include Writable
    include Readable
  end
end
