window.TestFixtures = {
  relationships_table: {
    child_id: 'child1234',
    parent_id: 'parent5678'
  }
}

window.TestFixtures.relationships_table["html"] =
"<form action='/concern/generic_works/#{TestFixtures.relationships_table.child_id}'><table class='table table-striped related-files relationships-ajax-enabled'> <thead> <tr> <th>Parent Work</th> <th>Actions</th> </tr> </thead> <tbody> <tr class='new-row'> <td> <a href='' class='title hidden'></a>
<input id=\"find_child_work\" name='find_child_work' value='' data-autocomplete=\"work\"> <div class='message has-warning hidden'></div> </td> <td> <div class='child-actions'> <a href='' class='edit hidden btn btn-default' target='_blank'>Edit</a> <a class='btn btn-danger btn-remove-row hidden'>Remove</a> <a class='btn btn-primary btn-add-row'>Add</a></div></td></tr></tbody></table></form>

<script type=\"text/x-tmpl\" id=\"tmpl-child-work\">
<tr>
  <td>{%= o.title %}</td>
  <td><button class=\"btn btn-danger\" data-behavior=\"remove-relationship\">Remove</button></td>
</tr>
</script>
"
