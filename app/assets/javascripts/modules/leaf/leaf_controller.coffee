@Notable.module "Leaf", (Leaf, App, Backbone, Marionette, $, _) ->
	Leaf.startWithParent = false

	Leaf.Controller = Marionette.Controller.extend
		initialize: ->
			@setEvents()
			@setGlobals()
		start: ->
			App.Notebook.initializedTrunk.then =>
				notebook_id = App.Notebook.activeTrunk.id
				@startBloodhound(notebook_id)

		startBloodhound: (id) ->
			engine = new Bloodhound
				limit: 5
				local: [{suggestion: "Notable"}]
				prefetch: '/suggestions.json'
				remote: 'suggestions/'+id+'.json?q=%QUERY'
				dupDetector: (remote, local) ->
					remote.suggestion is local.suggestion
				datumTokenizer: (d) ->
					Bloodhound.tokenizers.whitespace(d.suggestion)
				queryTokenizer: Bloodhound.tokenizers.whitespace
			engine.clear()
			engine.clearPrefetchCache()
			bloodhoundInitialized = engine.initialize(true)
			bloodhoundInitialized
				.done( => @startTypeAhead(engine) )
				.fail( -> console.log('Error with Bloodhound') )
		startTypeAhead: (engine) ->
			$(".note-content").typeahead
				minLength: 3
				highlight: true
			,
				name: "suggestions"
				displayKey: "suggestion"
				source: engine.ttAdapter()
		setGlobals: ->
			# @exportLeafUser = new App.Leaf.ExportModel()
			# User.activeUserInitialized = $.Deferred()
			# User.activeUser = @activeUser
			# User.idle = true
		setEvents: ->
		# evernoteEventListeners:
		# 	sync_flow: ->
		# 		$('.sync-with-Leaf').on 'click', (e) ->
		# 			e.preventDefault()

	# Initializers -------------------------
	Leaf.addInitializer ->
		Leaf.leafController = new Leaf.Controller()
		Leaf.leafController.start()
