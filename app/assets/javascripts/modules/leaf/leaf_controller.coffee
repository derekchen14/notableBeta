@Notable.module "Leaf", (Leaf, App, Backbone, Marionette, $, _) ->
	Leaf.startWithParent = false
	Leaf.eventManager = _.extend {}, Backbone.Events

	Leaf.Controller = Marionette.Controller.extend
		initialize: ->
			@leafCollection = new App.Leaf.LeafCollection()
			@eventManager = Leaf.eventManager
			@setGlobals()
			@setEvents()
		start: ->
			App.Notebook.initializedTrunk.then =>
				notebook_id = App.Notebook.activeTrunk.id
				@startBloodhound(notebook_id)
				@leafCollection.fetch
					success: ->
						Leaf.initializedLeaves.resolve()
		setGlobals: ->
			filepicker.setKey("AsJRTD9qQfyTSHqSr3VGAz")
			Leaf.initializedLeaves = $.Deferred()
			Leaf.allLeaves = @leafCollection
		setEvents: ->
			@eventManager.on "typeahead:attach", @attachTypeahead, @

		startBloodhound: (id) ->
			@engine = new Bloodhound
				limit: 4
				local: [{suggestion: "sophomore"}, {suggestion: "achieve"}, {suggestion: "apparent"},
					{suggestion: "calendar"}, {suggestion: "congratulate"}, {suggestion: "desperate"},
					{suggestion: "receive"}, {suggestion: "ignorance"}, {suggestion: "judgment"},
					{suggestion: "conscious"}, {suggestion: "February"}, {suggestion: "definition"}]
				prefetch: '/suggestions.json'
				remote: 'suggestions/'+id+'.json?q=%QUERY'
				dupDetector: (remote, local) ->
					remote.suggestion is local.suggestion
				datumTokenizer: (d) ->
					Bloodhound.tokenizers.whitespace(d.suggestion)
				queryTokenizer: Bloodhound.tokenizers.whitespace
			@engine.clear()
			@engine.clearPrefetchCache()
			bloodhoundInitialized = @engine.initialize(true)
			# bloodhoundInitialized
			# 	.done( => console.log "Bloodhound initialized" )
			# 	.fail( -> console.log "Error with Bloodhound" )
		attachTypeahead: (input) ->
			input.typeahead
				minLength: 3
				highlight: true
			,
				name: "suggestions"
				displayKey: "suggestion"
				source: @engine.ttAdapter()

	# Initializers -------------------------
	Leaf.addInitializer ->
		Leaf.leafController = new Leaf.Controller()
		Leaf.leafController.start()
