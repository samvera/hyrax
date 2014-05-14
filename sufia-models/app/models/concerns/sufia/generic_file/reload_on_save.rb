# add this in here until we can use a version of Active Fedora that contains this ability
module Sufia
  module GenericFile
    module ReloadOnSave

      attr_writer :reload_on_save

      def reload_on_save?
        !!@reload_on_save
      end

      def refresh
        self.reload if reload_on_save?
      end
    end
  end
end

