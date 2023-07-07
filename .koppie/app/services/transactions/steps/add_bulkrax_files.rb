# frozen_string_literal: true

# require "dry/monads"

# module Transactions
#   module Steps
#     class AddBulkraxFiles
#       include Dry::Monads[:result]

#       ##
#       # @param [Class] handler
#       def initialize(handler: Hyrax::WorkUploadsHandler)
#         @handler = handler
#       end

#       ##
#       # @param [Hyrax::Work] obj
#       # @param [Array<Fog::AWS::Storage::File>] file
#       # @param [User] user
#       #
#       # @return [Dry::Monads::Result]
#       def call(obj, files:, user:)
#         if files && user
#           begin
#             files.each do |file|
#               FileIngest.upload(
#                 content_type: file.content_type,
#                 file_body: StringIO.new(file.body),
#                 filename: Pathname.new(file.key).basename,
#                 last_modified: file.last_modified,
#                 permissions: Hyrax::AccessControlList.new(resource: obj),
#                 size: file.content_length,
#                 user: user,
#                 work: obj
#               )
#             end
#           rescue => e
#             Hyrax.logger.error(e)
#             return Failure[:failed_to_attach_file_sets, files]
#           end
#         end

#         Success(obj)
#       end
#     end
#   end
# end
