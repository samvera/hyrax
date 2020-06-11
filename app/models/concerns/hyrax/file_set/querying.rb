# frozen_string_literal: true
module Hyrax
  class FileSet
    module Querying
      extend ActiveSupport::Concern

      module ClassMethods
        def where_digest_is(digest_string)
          where "digest_ssim" => urnify(digest_string)
        end

        def urnify(digest_string)
          "urn:sha1:#{digest_string}"
        end
      end
    end
  end
end
