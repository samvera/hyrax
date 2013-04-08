require 'open3'
module Sufia
  module FileContent
    module ExtractMetadata
      include Open3

      def extract_metadata
        out = nil
        to_tempfile do |f|
          out = run_fits!(f.path)
        end
        out
      end

      def to_tempfile &block
        return unless has_content?
        tmp_base = Sufia::Engine.config.temp_file_base
        f = Tempfile.new("#{pid}-#{dsVersionID}")
        f.binmode
        if content.respond_to? :read
          f.write(content.read)
        else
          f.write(content)
        end
        f.close
        content.rewind if content.respond_to? :rewind
        yield(f)
        f.unlink
      end

      # Return true if the content is present
      # You can override this method if your content is an external datastream
      def has_content?
        !content.nil?
      end

      private 


        def run_fits!(file_path)
            command = "#{fits_path} -i \"#{file_path}\""
            stdin, stdout, stderr, wait_thr = popen3(command)
            stdin.close
            out = stdout.read
            stdout.close
            err = stderr.read
            stderr.close
            exit_status = wait_thr.value
            raise "Unable to execute command \"#{command}\"\n#{err}" unless exit_status.success?
            out
        end


        def fits_path
          Sufia::Engine.config.fits_path
        end

      end
    end
end
