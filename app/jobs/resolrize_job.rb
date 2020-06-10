# frozen_string_literal: true
class ResolrizeJob < Hyrax::ApplicationJob
  def perform
    ActiveFedora::Base.reindex_everything
  end
end
