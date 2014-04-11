@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.Breadcrumb extends Backbone.Model
		initialize: (branch) ->
			@attributes = {}
			if (route = branch.get('route'))?
				@set "route", route
			else
				@set "route", "#/#{branch.get('guid')}"
			@set "title", @getBranchTitle(branch)
			@set "depth", branch.get('depth')

			if @get("depth") is -1
				@listenTo App.Notebook.activeTrunk, "change:title", @updateNotebookTitle

		updateNotebookTitle: ->
			@set "title", App.Notebook.activeTrunk.get("title")
		getBranchTitle: (branch) ->
			title = branch.get('title')
			if title.length > 14 and branch.id > 0
				return title.slice(0,14).concat("..")
			else
				return title

	class Note.Breadcrumbs extends Backbone.Collection
		model: Note.Breadcrumb
		initialize: (models, branch) ->
			@buildBreadcrumbs(branch) if branch isnt "root"
			@addRoot()

		addRoot: ->
			activeTrunkTitle = App.Notebook.activeTrunk.attributes.title
			breadcrumb = new Note.Breadcrumb
				attributes:
					route: "#/"
					title: activeTrunkTitle
					depth: -1

				get: (attr) ->
					@attributes[attr]

			@add breadcrumb

		buildBreadcrumbs: (branch) ->
			breadcrumb = new Note.Breadcrumb branch
			@add breadcrumb
			return if branch.isARoot()
			@buildBreadcrumbs App.Note.tree.findNote branch.get 'parent_id'

		comparator: (breadcrumb) ->
			breadcrumb.get('depth')

)
