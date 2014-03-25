@Notable.module "User", (User, App, Backbone, Marionette, $, _) ->
	User.startWithParent = false

		# Public -------------------------
	User.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@activeUser = new App.User.UserModel()
			@setEvents()
			@setGlobals()
		start: ->
			@activeUser.fetch success: (user) ->
				User.activeUserInitialized.resolve() if user.id?
		setGlobals: ->
			User.activeUserInitialized = $.Deferred()
			User.activeUser = @activeUser
			User.idle = true
		setEvents: ->

	# Initializers -------------------------
	User.addInitializer ->
		User.userController = new User.Controller()
		User.userController.start()
		# new Notebook.Router controller: Notebook.controller
