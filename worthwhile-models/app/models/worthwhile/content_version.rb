module Worthwhile
  class ContentVersion
    class Null
      def initialize(content)
      end
      def created_on; 'unknown'; end
      def committer_name; 'unknown'; end
      def formatted_created_on(*args); 'unknown'; end
      def version_id; 'unknown'; end
    end

    attr_reader :version_id, :created_on, :committer_name
    def initialize(content, version_structure)
      @created_on = version_structure.dsCreateDate
      @version_id = version_structure.versionID
      @committer_name = content.version_committer(version_structure)
    end

    def formatted_created_on(format = :long_ordinal )
      created_on.localtime.to_formatted_s(format)
    end
  end
end