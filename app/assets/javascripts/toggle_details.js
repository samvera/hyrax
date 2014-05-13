$(function(){
  //NOTE: This function is tightly coupled with the catalog index markup
  $('.show-details').on('click', function(event){
    event.preventDefault();
    $('.extended-attributes', $(this).parents('li'))
      .toggleClass('hide');
  });
});
