@Notable = do (Backbone, Marionette) ->
	# Create application root object and default regions
	App = new Marionette.Application

	App.addRegions
		messageRegion: "#message-region"
		contentRegion: "#content-region"
		sidebarRegion: "#sidebar-region"
		linksRegion: "#links-region"

	# Run BEFORE/DURING/AFTER initializers
	App.on "initialize:before", ->
		App.module("Scaffold").start()

	App.addInitializer ->
		App.module("User").start()
		App.module("Action").start()
		App.module("Notebook").start()
		App.module("Note").start()
		App.module("Leaf").start()
		App.module("Notify").start()
		# App.module("Modview").start()
		# App.module("Tag").start()

	App.on "initialize:after", ->
		App.module("Evernote").start()
		App.module("Wiring").start()
		if Backbone.history
			Backbone.history.start()
			# {pushState:true}

	App

$ ->
	Notable.start()
