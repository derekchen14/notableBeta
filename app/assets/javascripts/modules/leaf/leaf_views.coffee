@Notable.module("Leaf", (Leaf, App, Backbone, Marionette, $, _) ->

	class Leaf.LeafView extends Marionette.ItemView
		id: "leaves"
		className: "col-sm-4"
		tagName: "span"
		template: "leaf/leafModel"
		ui:
			attach: ".attach-drop"

		events: ->
			"click .icon-leaves-tag": "displayTag"
			"click .icon-leaves-attach": "displayAttach"
			"click .icon-leaves-emoticon": "displayEmoticon"

			"click .add-tag-btn": "addTag"
			"click .icon-leaves-share": "shareNote"
			"click .attach-btn": "attachFile"
			"click .icon-leaves-export": "exportParagraph"
			"click .emoticon-btn": "selectEmoticon"

		initialize: ->
			@cursorApi = App.Helper.CursorPositionAPI
		onRender: ->
			if source = @model.attributes.attach_src
				@showAttachment(source, @model.attributes.mimetype)
		onClose: ->
			@$el.off()

		displayAttach: ->
			$(".crown-attach").toggle()
			if @model.attributes.attach_size>1 then $(".attach-btn").text("Change File")
			@createDropTarget()  # move to initialize
		displayEmoticon: ->
			# App.Note.eventManager.trigger "concealLeaf"
			$(".crown-emoticon").toggle()

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
				@postPickProcessing(InkBlob)
			), (pickError) ->
				console.log pickError.toString()
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
					@postPickProcessing(InkBlob[0])
				onError: (type, message) ->
					console.log type+" : "+message
					App.Notify.alert 'attachError', 'danger'
		postPickProcessing: (InkBlob) ->
			App.Notify.alert "loading", "warning"
			@ui.attach.removeClass("over")
			$('.crown-attach').hide()
			App.Note.eventManager.trigger "concealLeaf"
			@determineFileType(InkBlob, InkBlob.mimetype)
		determineFileType: (InkBlob, mimetype) ->
			front = mimetype.slice(0,3)
			back = mimetype.slice(-3)
			if front is "ima"
				@displayImage(InkBlob, mimetype)
			else if back is "pdf"
				@displayFile(InkBlob, "PDF")
			else if back is "ord" or back is "ent"
				@displayFile(InkBlob, "Word Doc")
			else if back is "int" or back is "ion"
				@displayFile(InkBlob, "PowerPoint")
			else
				App.Notify.alert "attachError", "warning"

		displayImage: (InkBlob, type) ->
			filepicker.read InkBlob,
				base64encode: true
				cache: true
			, ((imageData) =>
				image_source = "data:"+type+";base64,"+imageData
				@saveAttachment(image_source, "image", InkBlob)
			), (pickError) ->
				console.log pickError.toString()
				App.Notify.alert "attachError", "danger"
		displayFile: (InkBlob, type) ->
			$.getJSON "/attach",
				doc: InkBlob.url
			, ((fileData) =>
				file_source = "https://view-api.box.com/1/sessions/"+fileData.sessionID+"/view?theme=dark"
				@saveAttachment(file_source, type, InkBlob)
			), (pickError) ->
				console.log pickError.toString()
				App.Notify.alert "attachError", "danger"

		saveAttachment: (source, type, blob) ->
			@model.save
				attach_src: source
				mimetype: type
				filename: blob.filename
				attach_size: blob.size
				note_id: App.Note.activeBranch.attributes.id
				patch: true
			, success: =>
				@showAttachment(source, type)
				App.Notify.alert "attachSuccess", "success", {dynamicText: type}
			, error: ->
				App.Notify.alert "attachError", "danger"
		showAttachment: (source, type) ->
			$("#display-region").empty()
			if type is "image"
				$attachment = $('<img class="attach-image"></img>')
			else
				$attachment = $('<iframe class="attach-file"></iframe>')
				$attachment.attr("allowfullscreen","true")
				$chevron = $('<span></span>').appendTo("#display-region")
				$chevron.addClass("glyphicon glyphicon-chevron-down fire")
			$attachment.attr("src", source).prependTo("#display-region")

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