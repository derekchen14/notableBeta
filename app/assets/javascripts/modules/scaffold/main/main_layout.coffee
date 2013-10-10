@Notable.module("Scaffold.Main", (Main, App, Backbone, Marionette, $, _) ->

	class Main.Layout extends Marionette.Layout
	  template: "scaffold/main/layout"
	  regions:
	    message_center: "#message_center"
	    content_center: "#content_center"

	layout = new Main.Layout()
	layout.render()

	layout.message_center.show(myMessage);
	layout.content_center.show(myContent);
)