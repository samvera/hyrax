module CurationConcerns
  module Permissions
    extend ActiveSupport::Concern
    include CurationConcerns::Permissions::Writable
    include CurationConcerns::Permissions::Readable
  end
end
