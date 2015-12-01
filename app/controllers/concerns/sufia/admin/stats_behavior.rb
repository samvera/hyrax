module Sufia
  module Admin
    module StatsBehavior
      extend ActiveSupport::Concern

      included do
        include Sufia::Admin::DepositorStats
      end

      def index
        # total user count
        @users_count = ::User.count

        # The most recent users to join
        @users_stats = params.fetch(:users_stats, {})
        @recent_users = recent_users

        # Query Solr for top depositors
        @active_users = top_depositors

        # Count of documents by permissions
        @files_count = document_by_permission

        # Query Solr for top file formats
        @top_formats = top_formats

        @deposit_stats = params.fetch(:deposit_stats, {})
        @depositors = depositors(@deposit_stats)
        render 'index'
      end

      private

        def top_depositors_count
          count = params[:dep_count].to_i
          count.in?(5..20) ? count : 5
        end

        def document_by_permission
          return document_by_date_by_permission if @users_stats[:file_start_date]

          files_count = {}
          files_count[:total] = GenericWork.count
          files_count[:public] = GenericWork.where_public.count
          files_count[:registered] = GenericWork.where_registered.count
          files_count[:private] = files_count[:total] - (files_count[:registered] + files_count[:public])
          files_count
        end

        def document_by_date_by_permission
          start_date = DateTime.parse(@users_stats[:file_start_date])
          end_date = DateTime.parse(@users_stats[:file_end_date]).end_of_day unless @users_stats[:file_end_date].blank?
          files_count = {}
          files_count[:total] = GenericWork.find_by_date_created(start_date, end_date).count
          files_count[:public] = GenericWork.find_by_date_created(start_date, end_date).merge(GenericWork.where_public).count
          files_count[:registered] = GenericWork.find_by_date_created(start_date, end_date).merge(GenericWork.where_registered).count
          files_count[:private] = files_count[:total] - (files_count[:registered] + files_count[:public])
          files_count
        end

        def top_depositors
          depositor_key = Solrizer.solr_name('depositor', :stored_searchable, type: :string)
          top_data(depositor_key, top_depositors_count)
        end

        def top_formats
          format_key = Solrizer.solr_name('file_format', Solrizer::Descriptor.new(:string, :indexed, :multivalued))
          top_data(format_key, 5)
        end

        def top_data(key, limit)
          query_url = "#{ActiveFedora.solr_config[:url]}/terms?terms.fl=#{key}&terms.sort=count&terms.limit=#{limit}&wt=json&omitHeader=true"
          # Parse JSON response (looks like {"terms":{"depositor_tesim":["mjg36",3]}} for depositor)
          json = open(query_url).read
          tuples = begin
                     JSON.parse(json)['terms'][key]
                   rescue
                     []
                   end
          # Change to hash where keys = logins and values = counts
          Hash[*tuples]
        end

        def recent_users
          # no dates return the top 5
          return ::User.order('created_at DESC').limit(5) if @users_stats[:start_date].blank?

          start_date = DateTime.parse @users_stats[:start_date]
          end_date = DateTime.parse(@users_stats[:end_date]).end_of_day unless @users_stats[:end_date].blank?
          ::User.recent_users start_date, end_date
        end
    end
  end
end
