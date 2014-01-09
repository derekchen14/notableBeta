@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Note.startWithParent = false

	# Public -------------------------
	Note.eventManager = _.extend {}, Backbone.Events

	Note.Router = Marionette.AppRouter.extend
		appRoutes:
			"search/:results": "searchResults"
			":guid": "zoomIn"
			"": "clearZoom"

	Note.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@allNotesByDepth = new App.Note.Collection()
			@tree = new App.Note.Tree()
			@setGlobals()
			@setEvents()
		start: ->
			App.Notebook.initializedTrunk.then =>
				console.log App.Notebook.activeTrunk
				App.OfflineAccess.checkAndLoadLocal (_.bind @buildTree, @)
				App.Action.orchestrator = new App.Action.Orchestrator()
		reset: ->
			@tree._reset()
			@allNotesByDepth._reset()
			@allNotesByDepth.fetch
				data: notebook_id: App.Notebook.activeTrunk.id
				success: => @buildTree()
			Note.eventManager.trigger "clearZoom"
		setGlobals: ->
			Note.initializedTree = $.Deferred()
			Note.allNotesByDepth = @allNotesByDepth
			Note.tree = @tree
			Note.activeTree = @tree
			Note.activeBranch = "root"
		setEvents: ->
			Note.eventManager.on "clearZoom", @clearZoom, @
			Note.eventManager.on "render:export", @showExportView, @
			Note.eventManager.on "clear:export", @clearExportView, @
			Note.eventManager.on "activeTrunk:changed", @changeActiveTrunk, @

		buildTree: ->
			@allNotesByDepth.sort()
			@allNotesByDepth.validateTree()
			@allNotesByDepth.each (note) =>
				@tree.add(note)
			@showContentView(@tree)
			App.Note.initializedTree.resolve()

		# Export Feat
		showExportView: (model, paragraph) ->
			App.contentRegion.currentView.treeRegion.close()
			App.contentRegion.currentView.crownRegion.close()
			@exportView = new App.Feat.ExportView
				model: model
				collection: Note.activeTree
				inParagraph: paragraph
				title: App.Note.activeBranch.get('title')
			App.contentRegion.currentView.treeRegion.show @exportView
		clearExportView: ->
			@showContentView(App.Note.activeTree)
			@showCrownView()
		showContentView: (tree) ->
			App.contentRegion.currentView.treeRegion.close()
			@treeView = new App.Note.TreeView(collection: tree)
			App.contentRegion.currentView.treeRegion.show @treeView

		# Crown
		showCrownView: ->
				@crownView = new App.Note.CrownView(model: App.Note.activeBranch)
				App.contentRegion.currentView.crownRegion.show @crownView
		clearCrownView: ->
			if @crownView?
				@crownView.close()
				delete @crownView
			App.Note.activeBranch = "root"

		# Breadcrumbs
		showBreadcrumbView: ->
			if @breadcrumbView?
				@breadcrumbView.collection = new Note.Breadcrumbs null, Note.activeBranch
				@breadcrumbView.render()
			else
				@breadcrumbView = new App.Note.BreadcrumbsView(collection: new Note.Breadcrumbs null, Note.activeBranch)
			App.contentRegion.currentView.breadcrumbRegion.show @breadcrumbView
		showNotebookTitleView: ->
			if @notebookTitleView?
				@notebookTitleView.model = App.Notebook.activeTrunk
				@notebookTitleView.render()
			else
				notebook = model: App.Notebook.activeTrunk
				@notebookTitleView = new App.Notebook.NotebookTitleView notebook
			App.contentRegion.currentView.breadcrumbRegion.show @notebookTitleView
			App.Note.activeBranch = "root"

		searchResults: (results) ->
			App.Note.initializedTree.then =>
				Backbone.history.navigate 'search?q=#{query}'
				# See around Line 110 of note_tree.coffee
				App.Note.searchedTree = App.Note.getSearchedCollection results
				# Build the searchedTree based on JSON results returned from server
				@clearCrownView()
				@showContentView App.Note.filteredTree
				@showNotebookTitleView()
		clearZoom: ->
			App.Note.initializedTree.then =>
				Backbone.history.navigate '#'
				App.Note.activeTree = App.Note.tree
				@clearCrownView()
				@showContentView App.Note.tree
				@showNotebookTitleView()
				if Note.tree.first()?
					Note.eventManager.trigger "setCursor:#{Note.tree.first().get('guid')}"
		zoomIn: (guid) ->
			App.Note.initializedTree.then =>
				App.Note.activeTree = App.Note.tree.getCollection guid
				App.Note.activeBranch = App.Note.tree.findNote(guid)
				@showCrownView()
				@showContentView App.Note.activeTree
				@showBreadcrumbView()
				if Note.activeTree.first()?
					Note.eventManager.trigger "setCursor:#{Note.activeTree.first().get('guid')}"
				else
					Note.eventManager.trigger "setCursor:#{Note.activeBranch.get('guid')}"

		changeActiveTrunk: ->
			if Note.activeBranch is "root"
				@showNotebookTitleView()
			else
				@showBreadcrumbView()

			@reset()

	# Initializers -------------------------
	Note.addInitializer ->
		Note.noteController = new Note.Controller()
		Note.noteController.start()
		new Note.Router controller: Note.noteController
)
