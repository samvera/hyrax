module Hyrax
  module Arkivo
    CREATOR_TYPES = ['author', 'interviewer', 'director', 'scriptwriter',
                     'inventor', 'composer', 'cartographer', 'programmer', 'artist',
                     'bookAuthor'].freeze

    CONTRIBUTOR_TYPES = ['contributor', 'editor', 'translator', 'seriesEditor',
                         'interviewee', 'producer', 'castMember', 'sponsor', 'counsel',
                         'attorneyAgent', 'recipient', 'performer', 'wordsBy', 'commenter',
                         'presenter', 'guest', 'podcaster', 'reviewedAuthor', 'cosponsor'].freeze

    class MetadataMunger
      def initialize(metadata)
        @metadata = metadata
        @munged = {}
      end

      # @return [Hash]
      def call
        normalize_keys_and_values
        rename_key(from: 'url', to: 'related_url')
        rename_key(from: 'tags', to: 'keyword')
        extract_creator_and_contributor_from_creators
        @munged
      end

      private

        def normalize_keys_and_values
          # First, normalize camelCase symbols to underscore strings
          @metadata.each do |key, value|
            @munged[key.to_s.underscore] = Array.wrap(value)
          end
        end

        def rename_key(from:, to:)
          @munged[to] = @munged.delete(from) if @munged.key?(from)
        end

        def extract_creator_and_contributor_from_creators
          creator_names = []
          contributor_names = []
          @munged['creators'].each do |entry|
            entry['name'] ||= "#{entry.delete('lastName')}, #{entry.delete('firstName')}".strip
            creator_names << entry['name'] if Hyrax::Arkivo::CREATOR_TYPES.include?(entry['creatorType'])
            contributor_names << entry['name'] if Hyrax::Arkivo::CONTRIBUTOR_TYPES.include?(entry['creatorType'])
          end
          @munged['creator'] = creator_names if creator_names.present?
          @munged['contributor'] = contributor_names if contributor_names.present?
          @munged.delete('creators')
        end
    end
  end
end
