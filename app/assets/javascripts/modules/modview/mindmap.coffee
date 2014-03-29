@Notable.module "Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.BranchModview extends Marionette.CompositeView
		template: "modview/branch"
		className: "branch-template"
		ui:
			nodeContent: ">.branch .node-content"
			descendants: ">.branch .descendants"
		events: ->
			"blur >.branch>.node-content": "updateNote"
			"keydown > .branch > .node-content": @model.timeoutAndSave

		initialize: ->
			@collection = @model.descendants
			@bindKeyboardShortcuts()
			@listenTo @collection, "sort", @render
			Note.eventManager.on "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.on "render:#{@model.get('guid')}", @render, @
			Note.eventManager.on "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			Note.eventManager.on "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			@cursorApi = App.Helper.CursorPositionAPI
		onRender: ->
			@getNoteContent()
			App.Note.eventManager.trigger "setCursor:#{@model.get('guid')}"
			window.setTimeout =>
				@runCalculations()
				@restyleBranches()
				@restyleTree()
			, 0
		onClose: ->
			@.$el.off()
			$("#notebook-title").removeClass("modview")
			$("#breadcrumb-region").removeClass("modview")
			$(".container").removeClass("modview")
			Note.eventManager.off "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.off "render:#{@model.get('guid')}",  @render, @
			Note.eventManager.off "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}", @checkForLinks, @

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
			@.$el.on 'keydown', null, 'right', @arrowRightJumpLine.bind @
			@.$el.on 'keydown', null, 'left', @arrowLeftJumpLine.bind @
			@.$el.on 'keydown', null, 'backspace', @mergeWithPreceding.bind @
			@.$el.on 'keydown', null, 'del', @mergeWithFollowing.bind @
			@.$el.on 'keydown', null, 'ctrl+s meta+s', @triggerSaving.bind @
			@.$el.on 'keydown', null, 'ctrl+z meta+z', @triggerUndoEvent

		runCalculations: ->
			Note.mindmap.height = @calculateHeight()
			Note.mindmap.width = @calculateWidth()
			Note.mindmap.titleTop = @calculateTitleTop() if Note.mindmap.titleTop is 0
			Note.mindmap.titleLeft = @calculateTitleLeft() if Note.mindmap.titleLeft is 0
		calculateHeight: ->
			return 600
		calculateWidth: ->
			if "innerWidth" in window
				return window.innerWidth*0.94
			else
				return document.documentElement.offsetWidth*0.94
		calculateTitleTop: ->
			fullTop = Note.mindmap.height - $("#notebook-title")[0].offsetHeight
			(fullTop/2).toFixed(2)
		calculateTitleLeft: ->
			fullLeft = Note.mindmap.width - $("#notebook-title")[0].offsetWidth
			(fullLeft/2).toFixed(2)
		appendHtml:(collectionView, itemView, i) ->
			@$('.descendants:first').append(itemView.el)

		restyleTree: ->
			$("#notebook-title").css
				"top": Note.mindmap.titleTop+"px"
				"left": Note.mindmap.titleLeft+"px"

		restyleBranches: ->
			@nodeWidth = @ui.nodeContent.width()
			@rootSide = Note.mindmap.side
			@setRoots() if @model.isARoot true
		setRoots: ->
			@$(">.branch").first().addClass('root')
			Note.mindmap.side = if Note.mindmap.side is "left" then "right" else "left"
			@positionRoots()
		positionRoots: ->
			xLeft = (Note.mindmap.width/2)-200-@nodeWidth
			xRight = (Note.mindmap.width/2)+150
			console.log "xLeft:", xLeft
			@el.children[0].style.left = if @rootSide is "left" then xLeft+"px" else xRight+"px"

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
		triggerEvent: (event) ->
			(e) =>
				@updateNote()
				args = ['change', event, @model].concat(Note.sliceArgs arguments, 0)
				Note.eventManager.trigger.apply(Note.eventManager, args)
		triggerQueueEvent: (event) ->
			@shortcutTimer @triggerEvent(event)
		mergeWithPreceding: (e) ->
			e.stopPropagation()
			if @testCursorPosition "isEmptyBeforeCursor"
				@triggerShortcut('mergeWithPreceding')(e)
		mergeWithFollowing: (e) ->
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

		createNote: (e) ->
			e.preventDefault()
			e.stopPropagation()
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

		getSelectionAndTitle: ->
			[window.getSelection(), @getNoteTitle()]
		getNoteTitle: ->
			title = @getNoteContent().html().trim()
			App.Helper.tagRegex.trimEmptyTags title
		getNoteContent: ->
			if @ui.nodeContent.length is 0 or !@ui.nodeContent.focus?
				@ui.nodeContent = @.$('.node-content:first')
			@ui.nodeContent

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

	class Note.TreeModview extends Marionette.CollectionView
		id: "mindmap"
		itemView: Note.BranchModview

		initialize: ->
			@listenTo @collection, "sort", @render
			@listenTo @collection, "destroy", @addDefaultNote
			Note.eventManager.on 'createNote', @createNote, this
			Note.eventManager.on 'change', @dispatchFunction, this
			Note.eventManager.on 'renderTreeView', @render, this
		onBeforeClose: ->
			Note.eventManager.off 'createNote', @createNote, this
			Note.eventManager.off 'change', @dispatchFunction, this
			Note.eventManager.off 'renderTreeView', @render, this

		onRender: ->
			$("#breadcrumb-region").addClass("modview")
			$(".container").addClass("modview")
			$("#notebook-title").addClass("modview")

		dispatchFunction: (functionName, model) ->
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