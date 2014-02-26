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
//= require jquery
//= require jquery_ujs
//= require lib/underscore
//= require lib/backbone
//= require lib/marionette
//= require lib/sidr
//= require lib/hotkeys
//= require lib/modernizr
//= require lib/idle
//= require lib/bootbox
//= require handlebars
//= require bootstrap
//
// Next we load in configuration and all the core objects
//= require_tree ./config
//= require app
//= require_tree ./layout
//
// Now we can simply do require_tree for all the modules
//= require_tree ./modules/scaffold
//= require_tree ./modules/user
//= require_tree ./modules/note
//= require_tree ./modules/notebook
//= require_tree ./modules/notification
//= require_tree ./modules/action
//= require_tree ./modules/helpers
//= require_tree ./modules/breadcrumb
//= require_tree ./modules/feat
//= require_tree ./modules/evernote
