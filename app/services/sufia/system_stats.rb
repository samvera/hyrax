# A class that retrieves system level statistics about the system
#
# @attr_reader int limit      limits the results returned from top_depositors and top_formats
#                             Default is 5, maximum is 20, minimum is 5
# @attr_reader int start_date Filters the statistics returned by the class to after the start date
#                             blank means no filter
# @attr_reader int end_date   Filters the statistics returned by the class to before end date (end of day)
#                             blank means today
class Sufia::SystemStats
  attr_reader :limit, :start_date, :end_date

  # initialize the stats class setting the limitations
  #
  # @attr_reader int limit      limits the results returned from top_depositors and top_formats
  #                             Default is 5, maximum is 20, minimum is 5
  # @attr_reader int start_date Filters the statistics returned by the class to after the start date
  #                             blank means no filter
  # @attr_reader int end_date   Filters the statistics returned by the class to before end date (end of day)
  #                             blank means today
  def initialize(limit_records = 5, start_date_str = nil, end_date_str = nil)
    @limit = validate_limit(limit_records)
    @start_date = Time.zone.parse(start_date_str).beginning_of_day unless start_date_str.blank?
    @end_date = Time.zone.parse(end_date_str).end_of_day unless end_date_str.blank?
  end

  # returns the total files in the system filtered by the start_date and end_date if present
  #
  # @return [Hash] A hash with the total files by permission for the system
  # @option [Number] :total Total number of files without regard to permissions
  # @option [Number] :public Total number of files that have public permissions
  # @option [Number] :registered Total number of files that have registered (logged in) permissions
  # @option [Number] :private Total number of files that have private permissions
  def document_by_permission
    return document_by_date_by_permission if start_date

    files_count = {}
    files_count[:total] = query_service.count
    files_count[:public] = query_service.where_public.count
    files_count[:registered] = query_service.where_registered.count
    files_count[:private] = files_count[:total] - (files_count[:registered] + files_count[:public])
    files_count
  end

  # returns a list (of size limit) of system users (depositors) that have the most deposits in the system
  # @return [Hash] a hash with the user name as the key and the number of deposits as the value
  #    { 'cam156' => 25, 'hjc14' => 24 ... }
  def top_depositors
    top_data(depositor_field, limit)
  end

  delegate :depositor_field, to: DepositSearchBuilder

  # returns a list (of size limit) of file formats (mime_types) that have the most files in the system
  # @return [Hash] a hash with the file format as the key and the number of files as the value
  #    { 'png' => 25, 'pdf' => 24 ... }
  def top_formats
    format_key = Solrizer.solr_name('file_format', Solrizer::Descriptor.new(:string, :indexed, :multivalued))
    top_data(format_key, limit)
  end

  # returns [Array<user>] a list (of size limit) of users most recently registered with the system
  #
  def recent_users
    # no dates return the top few based on limit
    return ::User.order('created_at DESC').limit(limit) if start_date.blank?

    ::User.recent_users start_date, end_date
  end

  # returns [Number] the number of currently registered users
  #
  def users_count
    ::User.count
  end

  private

    def validate_limit(count)
      if count.blank? || count < 5
        5
      elsif count > 20
        20
      else
        count
      end
    end

    def document_by_date_by_permission
      files_count = {}
      files_count[:total] = query_service.find_by_date_created(start_date, end_date).count
      files_count[:public] = query_service.find_public_in_date_range(start_date, end_date).count
      files_count[:registered] = query_service.find_registered_in_date_range(start_date, end_date).count
      files_count[:private] = files_count[:total] - (files_count[:registered] + files_count[:public])
      files_count
    end

    def query_service
      @query_service ||= Sufia::QueryService.new
    end

    def solr_connection
      ActiveFedora::SolrService.instance.conn
    end

    def top_data(key, limit)
      # Grab JSON response (looks like {"terms": {"depositor_tesim": {"mjg36": 3}}} for depositor)
      json = solr_connection.get 'terms', params: { 'terms.fl' => key,
                                                    'terms.sort' => 'count',
                                                    'terms.limit' => limit,
                                                    wt: 'json',
                                                    'json.nl' => 'map',
                                                    omitHeader: 'true' }
      unless json
        Rails.logger.error "Unable to reach TermsComponent via Solr connection. Is it enabled in your solr config?"
        return []
      end

      json['terms'][key]
    end
end
