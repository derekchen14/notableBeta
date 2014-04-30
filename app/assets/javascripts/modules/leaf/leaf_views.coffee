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
					".pdf", ".ppt", ".pptx", ".doc", ".docx", ".png", ".gif", ".jpg"
				]
				services: "COMPUTER"
				maxSize: 5242880 # 5MB
			, ((InkBlob) =>
				@model.save
					attach_url: InkBlob.url
					filename: InkBlob.filename
					mimetype: InkBlob.mimetype
					attach_size: InkBlob.size
					note_id: App.Note.activeBranch.attributes.id
				@postPickProcessing(InkBlob)
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
					".pdf", ".ppt", ".pptx", ".doc", ".docx", ".png", ".gif", ".jpg"
				]
				maxSize: 5242880 # 5MB
				dragEnter: =>
					@ui.attach.addClass("over") # make something turn yellow
				dragLeave: =>
					@ui.attach.removeClass("over")
				onProgress: (percentage) =>
					@ui.attach.text "Uploading ("+percentage+"%)"
				onSuccess: (InkBlob) =>
					@model.save
						attach_url: InkBlob[0].url
						filename: InkBlob[0].filename
						mimetype: InkBlob[0].mimetype
						attach_size: InkBlob[0].size
						note_id: App.Note.activeBranch.attributes.id
					@postPickProcessing(InkBlob[0])
				onError: (type, message) ->
					console.log type+" : "+message
					App.Notify.alert 'attachError', 'warning'
		postPickProcessing: (InkBlob) ->
			@ui.attach.removeClass("over")
			$('.crown-attach').hide()
			App.Note.eventManager.trigger "concealLeaf"
			type = @fileType(InkBlob.mimetype)
			console.log type
			@pickNotification(type)
			@displayFile(type)
		fileType: (mimetype) ->
			front = mimetype.slice(0,3)
			back = mimetype.slice(-3)
			if front is "ima"
				return "image"
			else if back is "pdf"
				return "PDF"
			else if back is "ord" or back is "ent"
				return "Word Doc"
			else if back is "int" or back is "ion"
				return "PowerPoint"
			else
				App.Notify.alert "attachError", "warning"
		pickNotification: (type) ->
			App.Notify.alert "attachSuccess", "success", {dynamicText: type}
		displayFile: (type) ->
			# if type is "image"
			# 	filepicker.read
			# else
			# 	Box.viewAPI

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