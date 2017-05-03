# frozen_string_literal: true

class ResolrizeJob < ActiveJob::Base
  def perform
    ActiveFedora::Base.reindex_everything
  end
end
