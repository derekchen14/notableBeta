@Notable.module "Leaf", (Leaf, App, Backbone, Marionette, $, _) ->
	Leaf.startWithParent = false
	Leaf.eventManager = _.extend {}, Backbone.Events

	Leaf.Controller = Marionette.Controller.extend
		initialize: ->
			@eventManager = Leaf.eventManager
			@setGlobals()
			@setEvents()
		start: ->
			App.Notebook.initializedTrunk.then =>
				notebook_id = App.Notebook.activeTrunk.id
				@startBloodhound(notebook_id)
		setGlobals: ->
		setEvents: ->
			@eventManager.on "typeahead:attach", @attachTypeahead, @
			# @eventManager.on "pushProgress", @progressView.pushProgress, @

		startBloodhound: (id) ->
			@engine = new Bloodhound
				limit: 5
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
			bloodhoundInitialized
				.done( => console.log "empty" )
				.fail( -> console.log('Error with Bloodhound') )
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
