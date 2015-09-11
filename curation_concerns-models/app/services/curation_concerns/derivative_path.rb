module CurationConcerns
  class DerivativePath
    class << self
      # Path on file system where derivative file is stored
      def derivative_path_for_reference(object, destination_name)
        destination_name = destination_name.gsub(/^original_file_/, '')
        derivative_path(object, extension_for(destination_name), destination_name)
      end

      private

        def derivative_path(object, extension, destination_name)
          file_name = destination_name + extension
          File.join(CurationConcerns.config.derivatives_path, pair_path(object.id, file_name))
        end

        def pair_path(id, file_name)
          pair = id.split('').each_slice(2).map(&:join).join('/')
          "#{pair}-#{file_name}"
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
