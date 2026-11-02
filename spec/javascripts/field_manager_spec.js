describe('FieldManager', function() {
  var removeButton = function(formAttrs, groupAttrs) {
    var fixture = setFixtures(
      '<form ' + formAttrs + '>' +
        '<div class="multi_value form-group" ' + groupAttrs + '>' +
          '<label>Title</label>' +
          '<ul class="listing"><li class="field-wrapper"><input class="multi_value multi-text-field form-control" value="A"></li></ul>' +
        '</div>' +
      '</form>'
    );
    fixture.find('.multi_value.form-group').manage_fields();
    return fixture.find('.remove');
  };

  it('labels the Remove control with the form data-remove-text', function() {
    var $remove = removeButton('data-remove-text="Entfernen"', '');
    expect($remove.find('.controls-remove-text').text()).toEqual('Entfernen');
  });

  it("prefers the field's own data-remove-text", function() {
    var $remove = removeButton('data-remove-text="Entfernen"', 'data-remove-text="Supprimer"');
    expect($remove.find('.controls-remove-text').text()).toEqual('Supprimer');
  });

  it('falls back to the English default without data-remove-text', function() {
    var $remove = removeButton('', '');
    expect($remove.find('.controls-remove-text').text()).toEqual('Remove');
  });

  it('inserts the label as text, not markup', function() {
    var $remove = removeButton('data-remove-text="&lt;b&gt;x&lt;/b&gt;"', '');
    expect($remove.find('.controls-remove-text b').length).toEqual(0);
    expect($remove.find('.controls-remove-text').text()).toEqual('<b>x</b>');
  });
});
