module CurationConcerns
  class DerivativePath
    class << self
      # Path on file system where derivative file is stored
      def derivative_path_for_reference(object, destination_name)
        destination_name = destination_name.gsub(/^original_file_/, '')
        derivative_path(object, extension_for(destination_name), destination_name)
      end

      # @return [Array<String>] Array of paths to derivatives for this object.
      def derivatives_for_reference(object)
        Dir.glob(root_path(object).join("*")).select do |path|
          path.start_with?(path_prefix(object).to_s)
        end
      end

      private

        # @param [#id] object Object whose ID is used to generate root path
        # @return [String] Returns the root path where derivatives will be generated into.
        def root_path(object)
          Pathname.new(derivative_path(object, "", "")).dirname
        end

        # @return <Pathname> Full prefix of the path for object.
        def path_prefix(object)
          Pathname.new(CurationConcerns.config.derivatives_path).join(pair_path(object.id))
        end

        def derivative_path(object, extension, destination_name)
          file_name = destination_name + extension
          "#{path_prefix(object)}-#{file_name}"
        end

        def pair_path(id)
          id.split('').each_slice(2).map(&:join).join('/')
        end

        def extension_for(destination_name)
          case destination_name
          when 'thumbnail'
            ".#{MIME::Types.type_for('jpg').first.extensions.first}"
          else
            ".#{destination_name}"
          end
        end
    end
  end
end
