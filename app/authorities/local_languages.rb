# This is called by questioning authority (aka QA) to provide search
# results at /authorities/search/local/languages?q=<QUERY>
class LocalLanguages
  def initialize(_)
  end

  def search(query)
    LocalAuthority.entries_by_term('generic_works', 'language', query)
  end
end
