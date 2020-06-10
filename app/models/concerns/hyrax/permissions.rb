# frozen_string_literal: true
module Hyrax
  module Permissions
    extend ActiveSupport::Concern
    include Hyrax::Permissions::Writable
    include Hyrax::Permissions::Readable
  end
end
