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
				@showNotebookTitleView()
				App.Action.transporter.testServerConnection()
				Note.syncingCompleted.then => @buildTree()
		reset: (callback = ->) ->
			@tree._reset()
			@showControls()
			@allNotesByDepth._reset()
			@allNotesByDepth.fetch
				data: notebook_id: App.Notebook.activeTrunk.id
				success: => @buildTree(); callback()
			Note.eventManager.trigger "clearZoom"
		setGlobals: ->
			Note.initializedTree = $.Deferred()
			Note.syncingCompleted = $.Deferred()
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
			@allNotesByDepth.validateTree()
			@allNotesByDepth.each (note) =>
				@tree.add(note, silent:true)
			@showContentView(@tree)
			App.Helper.CursorPositionAPI.resetToTreeTop()
			Note.eventManager.trigger "notebook:applyZoom"
			App.Note.initializedTree.resolve()
			@showLinksFooter()

		showControls: ->
			$("#modview-region").show()
			$(".message-template").show()
			$("#notebook-title").css("opacity", "1")
		showLinksFooter: ->
			if _.isUndefined(App.linksRegion.currentView)
				linksView = new App.Scaffold.LinksView
				App.linksRegion.show linksView
				App.User.settings.shortcutToolbar()
		# Export Leaf
		showExportView: (model, paragraph) ->
			App.contentRegion.currentView.treeRegion.close()
			App.contentRegion.currentView.crownRegion.close()
			@exportView = new App.Leaf.ExportView
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
			@treeView = new App.Note.TreeView collection: tree
			App.contentRegion.currentView.treeRegion.show @treeView

		showProgressView: () ->
			App.contentRegion.currentView.treeRegion.close()
			@treeView = new App.Helper.ProgressView()
			App.contentRegion.currentView.treeRegion.show @treeView
		showEvernoteView: ->
			App.contentRegion.currentView.treeRegion.close()
			@clearCrownView()
			@showNotebookTitleView()
			collection = App.Evernote.notebooks = new App.Evernote.Notebooks
			collection.fetch()
			@treeView = new App.Evernote.NotebookView()
			App.contentRegion.currentView.treeRegion.show @treeView
			notebookOptions = new App.Evernote.CheckboxesView(collection: collection)
			@treeView.checkboxRegion.show notebookOptions

		# Crown
		showCrownView: ->
			@crownView = new App.Note.CrownView(model: App.Note.activeBranch)
			App.contentRegion.currentView.crownRegion.show @crownView
			if App.Leaf.activeLeaves
				@showLeavesView()
			else
				App.Leaf.initializedLeaves.then =>
					@showLeavesView()

		showLeavesView: ->
			@leafView = new App.Leaf.LeafView(model: App.Leaf.activeLeaves)
			App.contentRegion.currentView.crownRegion.currentView.leafRegion.show @leafView
		clearCrownView: ->
			if @crownView?
				@crownView.close()
				delete @crownView
			if @leafView?
				@leafView.close()
				delete @leafView
			App.Note.activeBranch = "root"
			App.Note.activeTree = App.Note.tree
			App.Leaf.activeLeaves = "none"

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
				return false if App.Note.activeBranch is 'root'
				 # triggered first to keep previous active branch (reset in @clearCrownView)
				App.Note.eventManager.trigkger "notebook:clearZoom"
				Backbone.history.navigate '#'
				@clearCrownView()
				@showContentView App.Note.tree
				@showNotebookTitleView()
				App.Helper.eventManager.trigger "zoomChrome"
				if Note.tree.first()?
					Note.eventManager.trigger "setCursor:#{Note.tree.first().get('guid')}"
		zoomIn: (guid) ->
			App.Note.initializedTree.then =>
				App.Note.activeTree = App.Note.tree.getCollection guid
				App.Note.activeBranch = App.Note.tree.getNote(guid)
				App.Leaf.activeLeaves = App.Leaf.allLeaves.getLeaf(App.Note.activeBranch.id)

				@showViewsOnZoom()
				App.Helper.eventManager.trigger "zoomChrome"
				@setCursorOnZoom()
				App.Note.eventManager.trigger "notebook:zoomIn", App.Note.activeBranch.get('guid')
		showViewsOnZoom: ->
			@showCrownView()
			@showContentView App.Note.activeTree
			@showBreadcrumbView()
		setCursorOnZoom: ->
			if Note.activeTree.first()?
					Note.eventManager.trigger "setCursor:#{Note.activeTree.first().get('guid')}"
				else
					Note.eventManager.trigger "setCursor:#{Note.activeBranch.get('guid')}"


		changeActiveTrunk: ->
			@showContentView(new Backbone.Collection)
			if Note.activeBranch is "root"
				@showNotebookTitleView()
			else
				@showBreadcrumbView()
			@reset(-> App.Notebook.activeTrunk.trigger "selected") if Notable.Notebook.initializedTrunk.state() is "resolved"
	# Initializers -------------------------
	Note.addInitializer ->
		Note.noteController = new Note.Controller()
		Note.noteController.start()
		new Note.Router controller: Note.noteController
)
