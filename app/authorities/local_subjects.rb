# This is called by questioning authority (aka QA) to provide search
# results at /authorities/search/local/subjects?q=<QUERY>
class LocalSubjects
  def initialize(_)
  end

  def search(query)
    LocalAuthority.entries_by_term('generic_works', 'subject', query)
  end
end
