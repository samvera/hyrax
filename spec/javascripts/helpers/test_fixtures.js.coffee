window.TestFixtures = {
  relationships_table: {
    child_id: 'child1234',
    parent_id: 'parent5678'
  }
}

window.TestFixtures.relationships_table["html"] = "<form action='/concern/generic_works/#{TestFixtures.relationships_table.child_id}'><table class='table table-striped related-files relationships-ajax-enabled' data-query-url='/concern/generic_works/$id'> <thead> <tr> <th>Parent Work</th> <th>Actions</th> </tr> </thead> <tbody> <tr class='new-row'> <td> <a href='' class='title hidden'></a> <input class='new-form-control string multi_value optional related_works_ids form-control multi-text-field' name='generic_work[in_works_ids][]' value='' aria-labelledby='generic_work_in_works_ids_label' type='text'> <div class='message has-warning hidden'></div> </td> <td> <div class='child-actions'> <a href='' class='edit hidden btn btn-default' target='_blank'>Edit</a> <a class='btn btn-danger btn-remove-row hidden'>Remove</a> <a class='btn btn-primary btn-add-row'>Add</a></div></td></tr></tbody></table></form>"

