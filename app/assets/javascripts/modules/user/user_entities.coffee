@Notable.module("User", (User, App, Backbone, Marionette, $, _) ->

	class User.UserModel extends Backbone.Model
		urlRoot: "/active_user"

		initialize: ->
			App.Note.eventManager.on("activeTrunk:changed", @setActiveNotebook.bind(@))

		setActiveNotebook: ->
			@set("active_notebook", App.Notebook.activeTrunk.id)
			@save()
		getActiveNotebook: ->
			trunk = @get('active_notebook')
			forest = App.Notebook.forest
			if trunk then forest.findWhere(id:trunk) else forest.first()

	class User.Users extends Backbone.Collection
		model: User
)
