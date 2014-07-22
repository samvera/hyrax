class ResolrizeJob
  def queue_name
    :resolrize
  end

  def run
    require 'active_fedora/version'
    active_fedora_version = Gem::Version.new(ActiveFedora::VERSION)
    minimum_feature_version = Gem::Version.new('6.4.4')
    if active_fedora_version >= minimum_feature_version
      ActiveFedora::Base.reindex_everything("pid~#{Sufia.config.id_namespace}:*")
    else
      ActiveFedora::Base.reindex_everything
    end
  end
end
