@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.BranchView extends Marionette.CompositeView
		template: "note/branchModel"
		className: "branch-template"
		ui:
			noteContent: ">.branch .note-content"
			descendants: ">.branch .descendants"
		events: ->
			"blur >.branch>.note-content": "updateNote"
			"paste >.branch>.note-content": "pasteContent"

			"click .destroy": @triggerEvent "deleteNote"
			"mouseover .titleLink": @makeClickable
			"mouseout .titleLink": @makeEditable
			# "mouseover .branch": @toggleDestroyLeaf "block"
			# "mouseout .branch": @toggleDestroyLeaf "none"
			"keydown > .branch > .note-content": @model.timeoutAndSave
			"click >.branch>.collapsable": "toggleCollapse"
			"dblclick >.branch>.bullet": "zoomIn"

			"dragstart .bullet": @triggerDragEvent "startMove"
			"dragend .bullet": @triggerDragEvent "endMove"
			"drop .dropTarget": @triggerDragEvent "dropMove"
			"dragenter .dropTarget": @triggerDragEvent "enterMove"
			"dragleave .dropTarget": @triggerDragEvent "leaveMove"
			"dragover .dropTarget": @triggerDragEvent "overMove"

			"click .tutorial": "showVideo"

		initialize: ->
			@collection = @model.descendants
			@bindKeyboardShortcuts()
			@listenTo @collection, "sort", @render
			@listenTo @model, "expand", @expand
			@listenTo @model, "collapse", @collapse
			Note.eventManager.on "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.on "render:#{@model.get('guid')}", @render, @
			Note.eventManager.on "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			Note.eventManager.on "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.on "expand:#{@model.get('guid')}", @expand, @
			Note.eventManager.on "collapse:#{@model.get('guid')}", @collapse, @
			@cursorApi = App.Helper.CursorPositionAPI
		onRender: ->
			@getNoteContent()
			@trimExtraDropTarget()
			App.Note.eventManager.trigger "setCursor:#{@model.get('guid')}"
			@renderCollapsed()
			App.Leaf.eventManager.trigger "typeahead:attach", @ui.noteContent
			@addRootStyling()
		appendHtml:(collectionView, itemView, i) ->
			@$('.descendants:first').append(itemView.el)
			if i is @collection.length - 1
				@$('>.branch>.descendants>.branch-template>.branch>.dropAfter.dropTarget')[0...-1].remove()
		trimExtraDropTarget: ->
			if @model.isARoot(true) and @model.get('rank') isnt 1
				@$(">.branch>.dropBefore").remove()
		renderCollapsed: ->
			if descendants = @collection.models.length isnt 0
				@$(">.branch>.bullet").addClass("collapsable")
			if @model.get('collapsed') then @collapse(true) else @expand()
		addRootStyling: ->
			@$(">.branch").first().addClass('root') if @model.isARoot true

		showVideo: (e) ->
			bootbox.dialog "<iframe width='560' height='315' frameborder='0' src='http://www.youtube.com/embed/B1Iwz2x0Gow' allowfullscreen></iframe>"
			e.stopPropagation()

		bindKeyboardShortcuts: ->
			@.$el.on 'keydown', null, 'return', @createNote.bind @
			@.$el.on 'keydown', null, 'ctrl+shift+backspace meta+shift+backspace', @triggerShortcut 'deleteNote'
			@.$el.on 'keydown', null, 'tab', @triggerShortcut 'tabNote'
			@.$el.on 'keydown', null, 'shift+tab', @triggerShortcut 'unTabNote'
			@.$el.on 'keydown', null, 'alt+right meta+right', @triggerShortcut 'tabNote'
			@.$el.on 'keydown', null, 'alt+left meta+left', @triggerShortcut 'unTabNote'
			@.$el.on 'keydown', null, 'alt+up meta+up', @triggerShortcut 'jumpPositionUp'
			@.$el.on 'keydown', null, 'alt+down meta+down', @triggerShortcut 'jumpPositionDown'
			@.$el.on 'keydown', null, 'up', @triggerShortcut 'jumpFocusUp'
			@.$el.on 'keydown', null, 'down', @triggerShortcut 'jumpFocusDown'
			@.$el.on 'keydown', null, 'alt+ctrl+left meta+ctrl+left', @triggerShortcut 'zoomOut'
			@.$el.on 'keydown', null, 'alt+ctrl+right meta+ctrl+right', @triggerShortcut 'zoomIn'
			@.$el.on 'keydown', null, 'right', @arrowRightJumpLine.bind @
			@.$el.on 'keydown', null, 'left', @arrowLeftJumpLine.bind @
			@.$el.on 'keydown', null, 'backspace', @mergeWithPreceding.bind @
			@.$el.on 'keydown', null, 'del', @mergeWithFollowing.bind @
			@.$el.on 'keydown', null, 'ctrl+up', @triggerLocalShortcut @collapse
			@.$el.on 'keydown', null, 'ctrl+down', @triggerLocalShortcut @expand
			@.$el.on 'keydown', null, 'ctrl+s meta+s', @triggerSaving.bind @
			# @.$el.on 'keydown', null, 'ctrl+y meta+y', @triggerRedoEvent
			@.$el.on 'keydown', null, 'ctrl+z meta+z', @triggerUndoEvent
			@.$el.on 'keydown', null, 'ctrl+b meta+b', @applyStyling.bind @, 'bold'
			@.$el.on 'keydown', null, 'ctrl+i meta+i', @applyStyling.bind @, 'italic'
			@.$el.on 'keydown', null, 'ctrl+u meta+u', @applyStyling.bind @, 'underline'
			@.$el.on 'keydown', null, 'ctrl+k meta+k', @applyStyling.bind @, 'strikeThrough'
			# App level keyboard shortcuts
			@.$el.on 'keydown', null, 'alt+shift+right', @openSidebar
			@.$el.on 'keydown', null, 'alt+shift+left', @closeSidebar

		onClose: ->
			@.$el.off()
			# delete @collection
			Note.eventManager.off "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.off "render:#{@model.get('guid')}",  @render, @
			Note.eventManager.off "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}", @checkForLinks, @
			Note.eventManager.off "expand:#{@model.get('guid')}", @expand, @
			Note.eventManager.off "collapse:#{@model.get('guid')}", @collapse, @
		applyStyling: (style, e) ->
			e.preventDefault()
			e.stopPropagation()
			App.User.idle = false # hideChrome only allowed when using keyboard shortcuts
			document.execCommand(style)
		triggerRedoEvent: (e) ->
			e.preventDefault()
			e.stopPropagation()
			App.Action.manager.redo()
		triggerUndoEvent: (e) ->
			e.preventDefault()
			e.stopPropagation()
			App.Action.manager.undo()
		triggerShortcut: (event) -> (e) =>
			e.preventDefault()
			e.stopPropagation()
			args = Note.sliceArgs arguments
			args.push
				cursorPosition: @cursorApi.textBeforeCursor window.getSelection(), @getNoteTitle()
			@triggerEvent(event).apply(@, args)
		triggerLocalShortcut: (behaviorFn) -> (e) =>
			e.preventDefault()
			e.stopPropagation()
			App.User.idle = false # hideChrome allowed only with active use of keyboard shortcuts
			behaviorFn.apply(@, Note.sliceArgs arguments)
		triggerDragEvent: (event) -> (e) =>
			@updateNote()
			e.dataTransfer = e.originalEvent.dataTransfer;
			Note.eventManager.trigger 'change', event, @ui, e, @model
			e.stopPropagation()
		triggerEvent: (event) ->
			(e) =>
				@updateNote()
				args = ['change', event, @model].concat(Note.sliceArgs arguments, 0)
				Note.eventManager.trigger.apply(Note.eventManager, args)
		triggerQueueEvent: (event) ->
			@shortcutTimer @triggerEvent(event)
		mergeWithPreceding: (e) ->
			return true if document.getSelection().isCollapsed is false
			e.stopPropagation()
			if @testCursorPosition "isEmptyBeforeCursor"
				@triggerShortcut('mergeWithPreceding')(e)
		mergeWithFollowing: (e) ->
			return true if document.getSelection().isCollapsed is false
			e.stopPropagation()
			if @testCursorPosition "isEmptyAfterCursor"
				@triggerShortcut('mergeWithFollowing')(e)

		arrowRightJumpLine: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyAfterCursor"
				@triggerShortcut('jumpFocusDown')(e)
		arrowLeftJumpLine: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyBeforeCursor"
				@triggerShortcut('jumpFocusUp')(e, true)

		zoomIn: ->
			Backbone.history.navigate "#/#{@model.get('guid')}"

		toggleCollapse: ->
			if @model.get('collapsed') then @expand() else @collapse()
		expand: ->
			if @collapsable() and @isCollapsed()
				App.Action.orchestrator.triggerAction('basicAction', @model, collapsed: false) if @model.get('collapsed')
				@ui.descendants.slideDown('fast')
				@$(">.branch>.bullet").removeClass("is-collapsed")
		collapse: (onLoad = false) ->
			if @collapsable() and not @isCollapsed()
				App.Action.orchestrator.triggerAction('basicAction', @model, collapsed: true) if not @model.get('collapsed')
				if onLoad
					@ui.descendants.hide()
					@$(">.branch>.bullet").addClass("is-collapsed")
				else
					@ui.descendants.slideUp('fast')
					window.setTimeout =>
						@$(">.branch>.bullet").addClass("is-collapsed")
					, 100
		collapsable: ->
			@collection.length isnt 0
		isCollapsed: ->
			"is-collapsed" in App.Helper.ieShim.classList(@$(">.branch>.bullet")[0])
		# toggleDestroyLeaf: (toggleType) ->
		# 	(e) ->
		# 		e.stopPropagation()
		# 		$("div[data-guid=#{@model.get 'guid'}] .trash_icon:first").css("display", toggleType)

		createNote: (e) ->
			e.preventDefault()
			e.stopPropagation()
			# console.log "Note Views"
			do create = =>
				sel = window.getSelection()
				title = @updateNote()
				textBefore = @cursorApi.textBeforeCursor sel, title
				textAfter = (@cursorApi.textAfterCursor sel, title).replace(/^\s/, "")
				Note.eventManager.trigger 'createNote', @model, textBefore, textAfter
				if textAfter.length > 0 then App.Action.manager.addHistory "compoundAction", {actions:2, previousActions: true}
		triggerSaving: (e) ->
			e.preventDefault()
			e.stopPropagation()
			@updateNote()
			App.Action.orchestrator.triggerSaving()
		updateNote: (forceUpdate = false) ->
			noteTitle = @getNoteTitle()
			noteSubtitle = "" #@getNoteSubtitle()
			if @model.get('title') isnt noteTitle or forceUpdate is true
				noteTitle = @checkForLinks()
				App.Action.orchestrator.triggerAction 'updateBranch', @model,
					title: noteTitle
					subtitle: noteSubtitle
			noteTitle

		pasteContent: (e) ->
			e.preventDefault()
			textBefore = @textBeforeCursor()
			if window.getSelection().isCollapsed is false
				window.getSelection().deleteFromDocument()
			textAfter = @textAfterCursor()
			pasteText = e.originalEvent.clipboardData.getData("Text")
			splitText = @splitPaste pasteText
			return App.Notify.alert 'exceedPasting', 'warning' if splitText.length > 100
			Note.eventManager.trigger "setTitle:#{@model.get('guid')}", textBefore + _.first(splitText), true
			[branchToFocus, cursorPosition] = @pasteNewNote _.rest(splitText), textAfter
			Note.eventManager.trigger "change", "renderBranch", @model
			Note.eventManager.trigger "setCursor:#{branchToFocus.get('guid')}", cursorPosition
			# Note.eventManager.trigger "setCursor:#{@model.get('guid')}", textBefore
		splitPaste: (text) ->
			reg = /\n/
			splitText = text.split(reg)
			_.filter splitText, (text) -> text isnt '\n' and text isnt '\r'
		pasteNewNote: (splitPaste, textAfter) ->
			return if not splitPaste?
			focusHash = null
			currentBranch = @model
			do rec = (text = _.first(splitPaste), splitPaste = _.rest(splitPaste)) =>
				return if not text?
				[currentBranch, _1, focusHash] = Note.tree.createNote(currentBranch, currentBranch.get('title'), text, silent:true)
				rec _.first(splitPaste), _.rest(splitPaste)
			@pasteLast currentBranch, textAfter
		pasteLast: (branch, textAfter) ->
			text = branch.get('title')
			branch.set('title', text + textAfter)
			[branch, text]

		getSelectionAndTitle: ->
			[window.getSelection(), @getNoteTitle()]
		getNoteTitle: ->
			title = @getNoteContent().html().trim()
			App.Helper.tagRegex.trimEmptyTags title
		getNoteContent: ->
			if @ui.noteContent.length is 0 or !@ui.noteContent.focus?
				@ui.noteContent = @.$('.note-content:first')
			@ui.noteContent

		link: /((\b((https?:\/\/)|(www\.))[-A-Z0-9+&@#\/%?=~_|!:,.;]+[\w\/])|([.\w]{3,100}\.(biz|co|com|edu|gov|io|net|org)\b))/ig
		# Known bug : links in a multi-line paste are not recognized immediately
		checkForLinks: ->
			cursorPosition = @textBeforeCursor()
			content = @getNoteContent()
			title = content.text()
			return content.html() unless (link = @getMatchingLinks title)?
			insertLinksBound = @insertLinks.bind(@, link) # creates a unary function which expects only a title
			title = insertLinksBound @escapeHtmlEntities @replaceLinks title # it allows for this nice flow of chained modifications
			content.html(title)
			Note.eventManager.trigger "setCursor:#{@model.get('guid')}", cursorPosition if cursorPosition
			title

		# Returns an array of all the links in the title
		getMatchingLinks: (title) ->
			title.match(@link)

		# Replace links with a given low-chance of conflicting text
		# this will allow us to escape html entities safely
		# while still having clear delimiations of where links should go
		linkReplacementText: "${{replace_link}}"
		replaceLinks: (title) ->
			title.replace(this.link, @linkReplacementText)
		escapeHtmlEntities: (title) ->
			@getNoteContent().text(title).html()

		# Finally replaces replacement texts with their links
		insertLinks: (links, title) ->
			_(links).each (link) =>
				title = title.replace @linkReplacementText, @linkify(link)
			title
		linkify: (text)->
			if text.match /\b(http)/
				text.replace(@link, "<a href='$1' target='_blank' class='titleLink'>$1</a>")
			else
				text.replace(@link, "<a href='http://$1' target='_blank' class='titleLink'>$1</a>")

		makeClickable: (e) ->
			e.target.contentEditable = false
		makeEditable: (e) ->
			$(e.target).removeAttr("contentEditable")
		setNoteTitle: (title, forceUpdate = false) ->
			@getNoteContent().html title
			@updateNote forceUpdate
		setCursor: (position = false) ->
			(noteContent = @getNoteContent()).focus()
			@cursorApi.setCursor noteContent, position
		textBeforeCursor: ->
			[sel, title] = @getSelectionAndTitle()
			@cursorApi.textBeforeCursor sel, title
		textAfterCursor: ->
			[sel, title] = @getSelectionAndTitle()
			@cursorApi.textAfterCursor sel, title
		keepTextBeforeCursor: (sel, title) ->
			textBefore = @cursorApi.textBeforeCursor sel, title
			@model.set
				title: textBefore
			textBefore
		keepTextAfterCursor: (sel, title) ->
			textAfter = @cursorApi.textAfterCursor sel, title
			@model.set
				title: textAfter
			textAfter
		testCursorPosition: (testPositionFunction) ->
			sel = window.getSelection()
			title = @getNoteTitle()
			@cursorApi[testPositionFunction](sel, title)

		openSidebar: ->
			App.Helper.eventManager.trigger "openSidr"
			App.Helper.eventManager.trigger "showChrome"
			App.Helper.controller.userIdle = true # so user will never go into focused typing mode when siebar is open
		closeSidebar: ->
			App.Helper.eventManager.trigger "closeSidr"
			App.Helper.controller.userIdle = false

	class Note.TreeView extends Marionette.CollectionView
		id: "tree"
		itemView: Note.BranchView

		initialize: ->
			@listenTo @collection, "sort", @render
			@listenTo @collection, "destroy", @addDefaultNote
			Note.eventManager.on 'createNote', @createNote, this
			Note.eventManager.on 'change', @dispatchFunction, this
			Note.eventManager.on 'renderTreeView', @render, this
			@drag = undefined
		onBeforeClose: ->
			Note.eventManager.off 'createNote', @createNote, this
			Note.eventManager.off 'change', @dispatchFunction, this
			Note.eventManager.off 'renderTreeView', @render, this
			@drag = undefined

		onRender: -> @addDefaultNote false
		addDefaultNote: (render = true) ->
			# if @collection.length is 0 then @collection.create()
			# @render if render
		dispatchFunction: (functionName, model) ->
			# Hack to prevent the position of the cursor to be chained further
			# down in the function stack
			args = Note.sliceArgs(arguments)[0...-1] if _.last(arguments).cursorPosition?
			if @[functionName]?
				@[functionName].apply(@, Note.sliceArgs arguments)
			else
				@collection[functionName].apply(@collection, args)
				position = _.last(arguments).cursorPosition || ""
				Note.eventManager.trigger "setCursor:#{arguments[1].get 'guid'}", position
			Note.eventManager.trigger "actionFinished", functionName, arguments[1]
		renderBranch: (branch) ->
			return @render() if branch.get('parent_id') is 'root'
			Note.eventManager.trigger "render:#{branch.get('parent_id')}"
		createNote: (createdFrom) ->
			[newNote, createdFromNewTitle, setFocusIn] =
				@collection.createNote.apply(@collection, arguments)
			Note.eventManager.trigger "setTitle:#{createdFrom.get('guid')}", createdFromNewTitle
			Note.eventManager.trigger "setCursor:#{setFocusIn.get('guid')}"
		deleteNote: (note) ->
			(@jumpFocusDown note, false) unless (@jumpFocusUp note, true)
			@collection.deleteNote note
		jumpFocusUp: (note, endOfLine = false) ->
			previousNote = @collection.jumpFocusUp note
			if not previousNote?
				return false unless Note.activeBranch isnt "root"
				previousNote = Note.activeBranch
			Note.eventManager.trigger "setCursor:#{previousNote.get('guid')}", endOfLine
		jumpFocusDown: (note, checkDescendants = true) ->
			followingNote = @collection.jumpFocusDown note, checkDescendants
			if followingNote
				Note.eventManager.trigger "setCursor:#{followingNote.get('guid')}"
				true
			else
				Note.eventManager.trigger "setCursor:#{note.get('guid')}", true
				false

		startMove: (ui, e, model) ->
			App.Action.manager.addHistory 'moveBranch', model
			@drag = model
			e.dataTransfer.effectAllowed = "move"
			e.dataTransfer.setData("text", model.get 'guid')
			$(".dropTarget").addClass('moving')
			ui.noteContent.css("opacity", "0.3")
		dropMove: (ui, e, referenceNote) ->
			@leaveMove ui, e
			e.stopPropagation()
			if @dropAllowed(referenceNote, @getDropType e)
				@[@getDropType(e)](referenceNote)
			Note.eventManager.trigger "setCursor:#{@drag.get('guid')}"
			$(".dropTarget").removeClass('moving')
		dropBefore: (following) ->
			@collection.dropBefore(@drag, following)
		dropAfter: (preceding) ->
			@collection.dropAfter(@drag, preceding)
		enterMove: (ui, e, note) ->
			dropType = @getDropType  e
			if @dropAllowed note, dropType
				@leafTipBefore(dropType, e) if dropType is "dropBefore"
				@leafTipAfter(dropType, e) if dropType is "dropAfter"
				$(e.currentTarget).addClass('over')
		leafTipBefore: (dropType, e) ->
			bullet = e.currentTarget.nextElementSibling.nextElementSibling
			$(bullet).addClass(dropType)
			$(e.delegateTarget).addClass("before")
			if e.delegateTarget.previousElementSibling
				bulletAfter = e.delegateTarget.previousElementSibling.children[0].children[2]
				$(bulletAfter).addClass("dropAfter")
		leafTipAfter: (dropType, e) ->
			bullet = e.currentTarget.previousElementSibling.previousElementSibling
			$(bullet).addClass(dropType)
			$(e.delegateTarget).addClass("after")
			if e.delegateTarget.nextElementSibling
				bulletBefore = e.delegateTarget.nextElementSibling.children[0].children[1]
				$(bulletBefore).addClass("dropBefore")
		leaveMove: (ui, e, note) ->
			$(".bullet").removeClass("dropBefore")
			$(".bullet").removeClass("dropAfter")
			$(e.currentTarget).removeClass('over')
			$(e.delegateTarget).removeClass("before")
			$(e.delegateTarget).removeClass("after")
		overMove: (ui, e, note) ->
			if @dropAllowed note, @getDropType e
				e.preventDefault()
				e.dataTransfer.dropEffect = "move"
			false
		endMove: (ui, e, note) ->
			ui.noteContent.css("opacity", "1")
			$(".dropTarget").removeClass('moving')
			@drag = undefined
		dropAllowed: (note, dropType) ->
			dropTypeMap =
				dropBefore: "dropAllowedBefore"
				dropAfter: "dropAllowedAfter"
			@[dropTypeMap[dropType]](note)
		dropAllowedBefore: (note) ->
			preceding = @collection.jumpFocusUp note
			not note.hasInAncestors(@drag) and (preceding isnt @drag or
			note.get('depth') isnt @drag.get 'depth')
		dropAllowedAfter: (note) ->
			@drag isnt note and not note.hasInAncestors @drag
		getDropType: (e) ->
			App.Helper.ieShim.classList(e.currentTarget)[1]
			# ui.noteContent.style.opacity = '0.7'
			# ui.noteContent.style.opacity = '1.0'

		mergeWithPreceding: (note) ->
			[preceding, title, previousTitle] = @collection.mergeWithPreceding note
			return false unless preceding?
			Note.eventManager.trigger "setTitle:#{preceding.get('guid')}", title, true
			Note.eventManager.trigger "setCursor:#{preceding.get('guid')}", previousTitle
		mergeWithFollowing: (note) ->
			[following, title, previousTitle] = @collection.mergeWithFollowing note
			return false unless following?
			Note.eventManager.trigger "setTitle:#{following.get('guid')}", title, true
			Note.eventManager.trigger "setCursor:#{following.get('guid')}", previousTitle

		zoomOut: ->
			if App.Note.activeBranch  isnt "root" and App.Note.activeBranch.get('parent_id') isnt "root"
				@zoomIn
					get: () -> App.Note.activeBranch.get('parent_id')
				# Note.eventManager.trigger "setCursor:#{App.Note.activeTree.first().get('guid')}"
				# Note.eventManager.trigger "setCursor:#{App.Note.tree.findNote(App.Note.activeBranch.get("guid").getCompleteDescendantList().first().get('guid'))}"
			else
				@clearZoom()
		zoomIn: (model) ->
			Backbone.history.navigate "#/#{model.get('guid')}"

		clearZoom: ->
			Backbone.history.navigate ""
			Note.eventManager.trigger "clearZoom"

	class Note.CrownView extends Marionette.Layout
		id: "crown"
		template: "note/crownModel"
		regions:
			leafRegion: "#leaf-region"
		ui:
			noteContent: ".note-content"
			leaves: "span#leaves"
		events: ->
			"blur .note-content": "updateNote"
			"keydown .note-content": @model.timeoutAndSave
			"click .leaf": "displayLeaf"
			"click .icon-leaves-delete": "deleteBranch"

		initialize: ->
			@cursorApi = App.Helper.CursorPositionAPI
			Note.eventManager.on "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.on "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.on "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			@$el.on 'keydown', null, 'return', @createBranch.bind @
			@$el.on 'keydown', null, 'up', @setCursor.bind @
			@$el.on 'keydown', null, 'down', @jumpFocusDown.bind @
			@$el.on 'keydown', null, 'right', @arrowRightJumpLine.bind @
			@$el.on 'keydown', null, 'alt+ctrl+left', @zoomOut.bind @
			@$el.on 'keydown', null, 'ctrl+shift+backspace', @deleteBranch.bind @
		onClose: ->
			@$el.off()
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.off "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.off "setTitle:#{@model.get('guid')}", @setNoteTitle, @

		createBranch: (e) ->
			e.preventDefault()
			e.stopPropagation()
			createdFrom = App.Note.activeTree.first()
			return App.messageRegion.currentView.createNote() if not createdFrom?
			[newNote, createdFromNewTitle, setFocusIn] =
				App.Note.tree.createNote App.Note.activeTree.first(), "", createdFrom.get('title')
			Note.eventManager.trigger "setTitle:#{createdFrom.get('guid')}", createdFromNewTitle
			Note.eventManager.trigger "setCursor:#{newNote.get('guid')}"

		updateNote: (forceUpdate = false) ->
			noteTitle = @getNoteTitle()
			noteSubtitle = "" #@getNoteSubtitle()
			if @model.get('title') isnt noteTitle or forceUpdate is true
				App.Action.orchestrator.triggerAction 'updateBranch', @model,
					title: noteTitle
					subtitle: noteSubtitle
			noteTitle
		getNoteTitle: ->
			title = @ui.noteContent.html().trim()
			App.Helper.tagRegex.trimEmptyTags title
		setNoteTitle: (title, forceUpdate = false) ->
			@ui.noteContent.html title
			@updateNote forceUpdate

		setCursor: (position = false) ->
			(noteContent = @ui.noteContent).focus()
			App.Helper.CursorPositionAPI.setCursor noteContent, position
		jumpFocusDown: (e) ->
			e.preventDefault()
			e.stopPropagation()
			Note.eventManager.trigger "setCursor:#{Note.activeTree.first().get('guid')}"
		arrowRightJumpLine: (e) ->
			e.stopPropagation()
			if @cursorApi.isEmptyAfterCursor window.getSelection(), @getNoteTitle()
				@jumpFocusDown e

		displayLeaf: (e) ->
			$(e.currentTarget).toggleClass('selected')
			$("span#leaves").toggleClass("grow")
			@ui.noteContent.toggleClass("shrink")
		deleteBranch: (e) ->
			@zoomOut(e)
			App.Note.tree.deleteNote @model

		zoomOut: (e) ->
			e.preventDefault()
			e.stopPropagation()
			if App.Note.activeBranch isnt "root" and App.Note.activeBranch.get('parent_id') isnt "root"
				@zoomIn App.Note.activeBranch.get('parent_id')
				# Note.eventManager.trigger "setCursor:#{App.Note.activeTree.first().get('guid')}"
			else
				@clearZoom()
		zoomIn: (guid) ->
			Backbone.history.navigate "#/#{guid}"
		clearZoom: ->
			Note.eventManager.trigger "clearZoom"

)
