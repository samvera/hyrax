module PSU
  module Noid
    def noid
      self.pid.split(":").last
    end

    protected
    def normalize_identifier
      params[:id] = "#{namespace}:#{params[:id]}" unless params[:id].start_with?(namespace)
    end

    def namespace
      Rails.application.config.id_namespace
    end
  end
end
