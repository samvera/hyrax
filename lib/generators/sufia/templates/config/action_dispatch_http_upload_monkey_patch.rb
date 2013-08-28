module ActionDispatch
  module Http
    class UploadedFile
      def closed?
        @tempfile.closed?
      end
      def close
        @tempfile.close
      end
    end
  end
end
