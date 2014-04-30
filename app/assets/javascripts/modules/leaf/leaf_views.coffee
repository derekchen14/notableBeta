@Notable.module("Leaf", (Leaf, App, Backbone, Marionette, $, _) ->

	class Leaf.LeafView extends Marionette.ItemView
		id: "leaves"
		className: "col-sm-4"
		tagName: "span"
		template: "leaf/leafModel"
		ui:
			attach: ".attach-drop"

		events: ->
			"click .icon-leaves-attach": "displayAttach"
			# "click .icon-leaves-tag": "addTag"

			"click .add-tag-btn": "addTag"
			"click .icon-leaves-share": "shareNote"
			"click .attach-btn": "attachFile"
			"click .icon-leaves-export": "exportParagraph"
			"click .emoticon-btn": "selectEmoticon"

		initialize: ->
			@cursorApi = App.Helper.CursorPositionAPI
		onClose: ->
			@$el.off()

		displayAttach: ->
			$(".crown-attach").toggle()  # move to crown views
			@createDropTarget()  # move to initialize

		addTag: ->
			console.log "Tag should be added"
		shareNote: ->
			App.Note.eventManager.trigger "render:export", @model, false
		# 	filepicker.exportFile 'https://d3urzlae3olibs.cloudfront.net/f71d50e/img/success.png'
		# 		mimetype:"image/png"
		# 	, (InkBlob) ->
		# 			console.log(InkBlob.url)
		attachFile: ->
			filepicker.pick
				extensions: [
					".pdf", ".ppt", ".pptx", ".doc", ".docx", ".png", ".gif", ".jpeg"
				]
				services: "COMPUTER"
				maxSize: 5242880 # 5MB
			, ((InkBlob) =>
				@model.save
					attachment: InkBlob.url
					# attach_url: InkBlob.url
					# filename: InkBlob.filename
					# mimetype: InkBlob.mimetype
					# attach_size: InkBlob.size
					note_id: App.Note.activeBranch.attributes.id
				@ui.attach.removeClass("over")
				$('.crown-attach').hide()
				App.Notify.alert 'attachSuccess', 'success'
			), (FPError) ->
				console.log FPError.toString()
				App.Notify.alert 'attachError', 'warning'
		exportParagraph: ->
			App.Note.eventManager.trigger "render:export", @model, true
		selectEmoticon:->
			console.log "emoticon should be selected"

		createDropTarget: ->
			filepicker.makeDropPane $(".attach-drop")[0],
				extensions: [
					".pdf", ".ppt", ".pptx", ".doc", ".docx", ".png", ".gif", ".jpeg"
				]
				maxSize: 5242880 # 5MB
				dragEnter: =>
					@ui.attach.addClass("over") # make something turn yellow
				dragLeave: =>
					@ui.attach.removeClass("over") # should also occur onSuccess
				onProgress: (percentage) =>
					@ui.attach.text "Uploading ("+percentage+"%)"
				onSuccess: (InkBlob) =>
					@model.save
						attachment: InkBlob[0].url
						# attach_url: InkBlob.url
						# filename: InkBlob.filename
						# mimetype: InkBlob.mimetype
						# attach_size: InkBlob.size
						note_id: App.Note.activeBranch.attributes.id
					@ui.attach.removeClass("over")
					$('.crown-attach').hide()
					App.Notify.alert 'attachSuccess', 'success'
				onError: (type, message) ->
					console.log type+" : "+message

	class Leaf.ExportView extends Marionette.ItemView
		id: "tree"
		template: "leaf/export"

		events: ->
			"click .glyphicon-remove": "clearExport"
		initialize: (options) ->
			@model = new Leaf.ExportModel tree: @collection, inParagraph: options.inParagraph, title: options.title
			if options.inParagraph then App.Notify.alert 'exportParagraph', 'success'
			else App.Notify.alert 'exportPlain', 'success'

		clearExport: ->
			App.Note.eventManager.trigger "clear:export"
)