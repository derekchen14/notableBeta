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
				@positionTitle()
				@positionNodes()
				@positionRoots() if @model.isARoot true
			, 0
		onClose: ->
			@.$el.off()
			$("#notebook-title").removeClass("modview")
			$("#breadcrumb-region").removeClass("modview")
			$(".container").removeClass("modview")
			$("canvas").remove()
			Note.eventManager.off "setCursor:#{@model.get('guid')}", @setCursor, @
			Note.eventManager.off "render:#{@model.get('guid')}",  @render, @
			Note.eventManager.off "setTitle:#{@model.get('guid')}", @setNoteTitle, @
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}", @updateNote, @
			Note.eventManager.off "timeoutUpdate:#{@model.get('guid')}", @checkForLinks, @
		appendHtml:(collectionView, itemView, i) ->
			@$('.descendants:first').append(itemView.el)

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
			Note.mindmap.height = @calculateHeight() if Note.mindmap.height is 0
			Note.mindmap.width = @calculateWidth() if Note.mindmap.width is 0
			Note.mindmap.titleTop = @calculateTitleTop() if Note.mindmap.titleTop is 0
			Note.mindmap.titleLeft = @calculateTitleLeft() if Note.mindmap.titleLeft is 0
		calculateHeight: ->
			if "innerWidth" in window
				if window.innerHeight < 1300 then 600 else 800
			else
				if document.documentElement.offsetWidth < 1300 then 600 else 800
		calculateWidth: ->
			if "innerWidth" in window
				return window.innerWidth*0.94
			else
				return document.documentElement.offsetWidth*0.94
		calculateTitleTop: ->
			fullTop = $("#content-center").height() - $("#notebook-title")[0].offsetHeight
			(fullTop/2).toFixed(2)
		calculateTitleLeft: ->
			fullLeft = Note.mindmap.width - $("#notebook-title")[0].offsetWidth
			(fullLeft/2).toFixed(2)

		positionTitle: ->
			$("#notebook-title").css
				"top": Note.mindmap.titleTop+"px"
				"left": Note.mindmap.titleLeft+"px"
		positionNodes: ->
			@nodeWidth = @el.children[0].offsetWidth
			@nodeHeight = @el.children[0].offsetHeight
		positionRoots: ->
			@rootSide = Note.mindmap.side
			@$(">.branch").first().addClass('root')
			@$(">.branch").first().addClass(@rootSide)
			Note.mindmap.side = if Note.mindmap.side is "left" then "right" else "left"
			@rootVertical()
			@rootHorizontal()

		rootVertical: ->
			if @rootSide is "right"
				Note.mindmap.stackRight.push @
			else
				Note.mindmap.stackLeft.push @
		rootHorizontal: ->
			left = (Note.mindmap.width/2)-200-@nodeWidth
			right = (Note.mindmap.width/2)+150
			@el.children[0].style.left = if @rootSide is "left" then left+"px" else right+"px"

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
			@setGlobals()
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
			window.setTimeout =>
				@calculateStack(Note.mindmap.stackRight)
				@calculateStack(Note.mindmap.stackLeft)
				@positionConnectors(2, 3, 4)
			, 0
		setGlobals: ->
			Note.mindmap =
				height: 0
				width: 0
				side: "right"
				titleTop: 0
				titleLeft: 0
				stackLeft: []
				stackRight: []

		calculateStack: (stack) ->
			if stack.length > 1
				stackHeight = @stackHeight(stack)
				totalHeight = stackHeight*1.4
				gap = (0.4*stackHeight)/(stack.length-1)
			else if stack.length is 1
				totalHeight = stack[0].nodeHeight
			else if stack.length is 0
				return
			@positionStack(stack, gap, totalHeight)
		positionStack: (stack, gap, totalHeight) ->
			offset = (Note.mindmap.height-totalHeight)/2
			branchCount = 0
			branches = @findBranchSide(stack, gap, totalHeight)
			for branch in branches
				branch.style.top = offset+"px"
				offset += stack[branchCount].nodeHeight
				offset += gap
				branchCount++
		stackHeight: (stack) ->
			stack.reduce (total, item) ->
				total + item.nodeHeight
			, 0
		findBranchSide: (stack, gap, totalHeight) ->
			if stack[0].rootSide is "right"
				@totalHeight = totalHeight
				@gapRight = gap
				return $(".branch.right")
			else if stack[0].rootSide is "left"
				@heightGap = (@totalHeight - totalHeight)/2
				@gapLeft = gap
				return $(".branch.left")

		positionConnectors: (item, side, children) ->
			canvas = @createCanvas()
			@drawConnectors(canvas, Note.mindmap.stackRight)
			@drawConnectors(canvas, Note.mindmap.stackLeft)
			@positionCanvas(canvas)
		createCanvas: ->
			canvas = document.createElement("canvas")
			canvas.width = 400
			canvas.height = @totalHeight
			return canvas
		drawConnectors: (canvas, stack) ->
			xStart = (canvas.width/2)
			yStart = (@totalHeight/2)-3
			xPoints = @findXPoints(canvas, stack)
			yPoints = @findYPoints(stack)
			xControls = @findXControls(stack)
			yControls = @findYControls(yPoints)
			xEnd = xStart
			yEnd = (@totalHeight/2)+2

			for connector in stack
				# console.log "yStart:",Math.round(yStart)," yControl:",Math.round(yControls[_i])," yPoint",Math.round(yPoints[_i])," yEnd:",Math.round(yEnd)
				# console.log "xStart:",Math.round(xStart)," xControl:",Math.round(xControls)," xPoint",xPoints," xEnd:",Math.round(xEnd)
				ctx = canvas.getContext("2d")
				ctx.fillStyle = ctx.strokeStyle = "#14A4FF"
				ctx.beginPath()
				ctx.moveTo xStart, yStart
				ctx.quadraticCurveTo xControls, yControls[_i], xPoints, yPoints[_i]
				ctx.quadraticCurveTo xControls, yControls[_i], xEnd, yEnd
				ctx.fill()
				ctx.stroke()
		findXPoints: (canvas, stack) ->
			if stack[0].rootSide is "right" then canvas.width else 0
		findYPoints: (stack) ->
			yPoints = []; i = 0
			yPrevious = if stack[0].rootSide is "right" then 0 else @heightGap
			do rec = (stack, yPrevious) =>
				yPoint = yPrevious + stack[i].nodeHeight/2
				yPoints.push yPoint
				yPrevious += stack[i].nodeHeight + @findGap(stack)
				i++; return false if stack.length is i
				rec stack, yPrevious
			return yPoints
		findGap: (stack) ->
			if stack[0].rootSide is "right" then @gapRight else @gapLeft
		findXControls: (stack) ->
			if stack[0].rootSide is "right" then 280 else 120
		findYControls: (yPoints) ->
			yControls = []; shift = 0.9
			yMidpoint = @totalHeight/2
			for point in yPoints
				if Math.round(yMidpoint) > Math.round(point)
					upshift = (yMidpoint-point)*shift
					yControl = yMidpoint-upshift
				else if Math.round(yMidpoint) < Math.round(point)
					downshift = (point-yMidpoint)*shift
					yControl = yMidpoint+downshift
				else # node midpoint is the same height as the title midpoint
					random = (Math.random()-0.5)*4
					randomShift = if random>0 then 10+random else -10+random
					yControl = yMidpoint+randomShift
				yControls.push yControl
			return yControls
		positionCanvas: (canvas) ->
			canvasTop = ($("#content-center").height() - canvas.height)/2
			canvasLeft = (Note.mindmap.width - canvas.width)/2
			canvas.style.top = canvasTop+"px"
			canvas.style.left = canvasLeft+"px"
			$("#breadcrumb-region").append(canvas)

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