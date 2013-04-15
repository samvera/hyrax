$(function() {
  function setup_autocomplete(obj, cloneElem) {
    // should we attach an auto complete based on the input
    if (obj.id == 'additional_based_near_submit') {
      cloneElem.find('input[type=text]').autocomplete(cities_autocomplete_opts);
    }
    else if ( (index = $.inArray(obj.id, autocomplete_vocab.add_btn_id)) != -1 ) {
      cloneElem.find('input[type=text]').autocomplete(get_autocomplete_opts(autocomplete_vocab.url_var[index]));
    }
  }

  $('form').multiForm({afterAdd: setup_autocomplete});
});
