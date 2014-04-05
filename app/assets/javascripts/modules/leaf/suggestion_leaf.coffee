@Notable.module "Leaf", (Leaf, App, Backbone, Marionette, $, _) ->
	Leaf.startWithParent = false

	App.Leaf =
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
			$("#query").typeahead
				minLength: 3
				highlight: true
			,
				name: "suggestions"
				displayKey: "suggestion"
				source: engine.ttAdapter()