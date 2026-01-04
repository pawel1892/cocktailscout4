// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require rails-ujs
//= require jquery3
//= require turbolinks
//= require foundation
//= require cocoon
//= require select2
//= require select2_locale_de
//= require_tree .

$(document).on('turbolinks:load', function() {
    $(function(){ $(document).foundation(); });
});

document.addEventListener('turbolinks:before-cache', function() { $('.select2-hidden-accessible').select2('destroy'); });

$(document).on('turbolinks:load', function() {
  $('.select2').select2();
});
