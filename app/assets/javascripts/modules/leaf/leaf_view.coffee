@Notable.module("Leaf", (Leaf, App, Backbone, Marionette, $, _) ->

	class Leaf.LeafView extends Marionette.ItemView
		id: "leaves"
		className: "col-sm-4"
		tagName: "span"
		template: "leaf/leafModel"

		events: ->
			"click .icon-leaves-attach": "displayAttach"
			"click .icon-leaves-export": "exportParagraph"
			"click .icon-leaves-emoticon": "displayEmoticon"
			"click .icon-leaves-delete": "deleteBranch"

			"click .tag-btn": "addTag"
			"click .icon-leaves-share": "shareNote"
			"click .attach-btn": "attachFile"
			"click .emoticon-btn": "selectEmoticon"

		initialize: ->
			@cursorApi = App.Helper.CursorPositionAPI
		onClose: ->
			@$el.off()

		displayAttach: ->
			$(".crown-attach").toggleClass('hidden')
			@createDropTarget()
		displayEmoticon: ->
			# @$(".icon-leaves-emoticon").toggleClass('selected')
		exportParagraph: ->
			App.Note.eventManager.trigger "render:export", @model, true

		shareNote: ->
			App.Note.eventManager.trigger "render:export", @model, false
		# 	filepicker.exportFile 'https://d3urzlae3olibs.cloudfront.net/f71d50e/img/success.png'
		# 		mimetype:"image/png"
		# 	, (InkBlob) ->
		# 			console.log(InkBlob.url)
		attachFile: ->
			filepicker.setKey("AsJRTD9qQfyTSHqSr3VGAz")
			filepicker.pick
				extensions: [
					".pdf", ".ppt", ".pptx", ".doc", ".docx", ".png", ".gif", ".jpeg"
				]
				services: "COMPUTER"
				maxSize: 5242880 # 5MB
			, ((InkBlob) ->
				console.log JSON.stringify(InkBlob)
			), (FPError) ->
				console.log FPError.toString()

		createDropTarget: ->
			filepicker.makeDropPane $(".attach-drop")[0],
				extensions: [
					".pdf", ".ppt", ".pptx", ".doc", ".docx", ".png", ".gif", ".jpeg"
				]
				dragEnter: ->
					$(".attach-drop").addClass("over")
				dragLeave: ->
					$(".attach-drop").removeClass("over")
				onSuccess: (InkBlob) ->
					console.log JSON.stringify(InkBlob)
				onError: (type, message) ->
					console.log type+" : "+message
				services: "COMPUTER"
				maxSize: 5242880 # 5MB


)
