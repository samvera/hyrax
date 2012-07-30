module GenericFileHelper
 def display_title(gf)
   title =  gf.title.join(' | ')
   title = gf.label if title.blank?
   return title
 end
end