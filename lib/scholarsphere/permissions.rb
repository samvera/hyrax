module Scholarsphere
  module GenericFile
    module Permissions

      # Copies and transforms permsisions set in params[:permission] into 
      # params[:generic_file][:read_groups_string] and params[:generic_file][:discover_groups_string]
      # Once this is done it becomes possible to do:
      # @generic_file.update_attributes(params[:generic_file])
      # Which will set the permissions correctly
      def self.parse_permissions(params)
        if params.has_key?(:permission)
          if params[:permission][:group][:public] == 'read'
            if params[:generic_file][:read_groups_string].present?
              params[:generic_file][:read_groups_string] << ', public'
            else 
              params[:generic_file][:read_groups_string] << 'public'
            end
          elsif params[:permission][:group][:public] == 'discover'
            params[:generic_file][:discover_groups_string] = 'public'
          end
          if params[:permission][:group][:registered] == 'read'
            if params[:generic_file][:read_groups_string].present?
              params[:generic_file][:read_groups_string] << ', registered'
            else 
              params[:generic_file][:read_groups_string] << 'registered'
            end
          elsif params[:permission][:group][:registered] == 'discover'
            params[:generic_file][:discover_groups_string] = 'registered'
          end
        end
      end
    end
  end
end
