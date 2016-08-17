module Sufia
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
      end

      def call
        munged = {}

        # First, normalize camelCase symbols to underscore strings
        @metadata.each do |key, value|
          munged[key.to_s.underscore] = Array.wrap(value)
        end

        # Then, rename the url key to related_url
        munged['related_url'] = munged.delete('url') if munged['url']

        # Then, rename the tags key to keyword
        munged['keyword'] = munged.delete('tags') if munged['tags']

        # Then, normalize creator names
        munged_creators = munged['creators'].each do |entry|
          next if entry['name']
          entry['name'] = "#{entry.delete('lastName')}, #{entry.delete('firstName')}".strip
        end

        # Then, parse creators and contributors out
        creator_names, contributor_names = split_creators_and_contributors(munged_creators)
        munged['creator'] = creator_names unless creator_names.blank?
        munged['contributor'] = contributor_names unless contributor_names.blank?

        # And remove the original creators array
        munged.delete('creators') if munged['creators']
        munged
      end

      private

        def split_creators_and_contributors(list_of_creators)
          creators = []
          contributors = []
          list_of_creators.each do |creator|
            creators << creator['name'] if Sufia::Arkivo::CREATOR_TYPES.include? creator['creatorType']
            contributors << creator['name'] if Sufia::Arkivo::CONTRIBUTOR_TYPES.include? creator['creatorType']
          end
          [creators, contributors]
        end
    end
  end
end
