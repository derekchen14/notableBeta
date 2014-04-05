@Notable.module "Leaf", (Leaf, App, Backbone, Marionette, $, _) ->
	Leaf.startWithParent = false

	App.Leaf =
		start: ->
			@engine = @startBloodhound()
			@bloodhoundPromise
				.done( => @startTypeAhead(@engine) )
				.fail( -> console.log('Error with Bloodhound') )
		startBloodhound: ->
			engine = new Bloodhound
				# name: 'suggestions'
				limit: 5
				local: [{suggestion: "Notable"}]
				prefetch: 'suggestions.json'
				# remote: 'suggestions.json'
				datumTokenizer: (d) ->
					Bloodhound.tokenizers.whitespace(d.suggestion)
				queryTokenizer: Bloodhound.tokenizers.whitespace
			engine.clear()
			engine.clearPrefetchCache()
			@bloodhoundPromise = engine.initialize(true)
			return engine
		startTypeAhead: (engine) ->
			$("#query").typeahead
				minLength: 3
				highlight: true
			,
				# name: "suggestions"
				displayKey: "suggestion"
				source: engine.ttAdapter()

