# frozen_string_literal: true
module Hyrax
  class FixityChecksController < ApplicationController
    before_action :authenticate_user!

    # request here with param :file_set_id will trigger a fixity check if
    # needed, and respond with a JSON hash that looks something like:
    #
    #     { "file_id" => [
    #         {
    #           "checked_uri" => "http://127.0.0.1:8986/rest/test/12/57/9s/28/12579s28n/files/3ff48171-f625-48bb-a73d-b1ba16dde530/fcr:versions/version1",
    #           "passed" => true,
    #           "expected_result" => "urn:sha1:03434..."
    #           "created_at" => "2017-05-16T15:32:50.961Z"
    #         }
    #       ]
    #     }
    def create
      render json: fixity_check_service.fixity_check
    end

    private

    def fixity_check_service
      # We are calling `async_jobs: false` to ensure we get a fixity result to
      # return even if there are no 'fresh' ones on record. Otherwise, we'd
      # have to sometimes return a 'in progress' status for some bytestreams,
      # which is a possible future enhancement.
      @fixity_check_service ||=
        FileSetFixityCheckService.new(::FileSet.find(params[:file_set_id]), async_jobs: false)
    end
  end
end
