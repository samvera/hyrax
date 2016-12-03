# -*- coding: utf-8 -*-
module FileSetHelper
  def present_terms(presenter, terms = :all, &block)
    terms = presenter.terms if terms == :all
    Hyrax::PresenterRenderer.new(presenter, self).fields(terms, &block)
  end
end
