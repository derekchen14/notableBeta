@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	Action.defaultAction = (branch, attributes, options = {}) ->
		branch: branch
		attributes: attributes
		previous_attributes: branch.attributes
		options: options
		compound: ->
		addToHistory: ->
		triggerNotification: ->
		destroy: false

	Action.buildAction = (actionType, branch, attributes, options = {}) ->
		args = App.Note.sliceArgs arguments
		_(Action[actionType].apply @, args).defaults(Action.defaultAction.apply @, args)

	Action.basicAction = -> {}

	Action.mergeWithPreceding = (branch, attributes, options = {}) ->
		_(
			compound: -> unless options.isUndo then App.Action.addHistory 'compoundAction', {actions: 2}
			triggerNotification: ->
		).defaults(Action.buildAction('deleteBranch', branch, attributes, options))

	Action.deleteBranch = (branch, attributes, options = {}) ->
		addToHistory:	-> unless options.isUndo then App.Action.addHistory 'deleteBranch', branch
		triggerNotification: -> unless options.isUndo then App.Notify.alert 'deleted', 'warning'
		destroy: true

	Action.createBranch = (branch, attributes, options = {}) ->
		# compound: -> unless options.isUndo then Action.addHistory "compoundAction", {actions:2}
		addToHistory: -> unless options.isUndo then Action.addHistory 'createNote', branch

	Action.updateContent = (branch, attributes, options = {}) ->
		addToHistory: -> unless options.isUndo then Action.addHistory 'updateContent', branch

	Action.processAction = (action) ->
		action.addToHistory()

	class Action.Orchestrator

		constructor: ->
			@savingQueue = []
			@validationQueue = []
			@actionQueue = []
			@destroyQueue = []
			@destroyGuidQueue = []

		queueAction: (action) ->
			# will have to play with the action manager
			@actionQueue.push action
		queueDestroy: (action) ->
			App.OfflineAccess.addDelete action.branch unless action.options.noLocalStorage
			@destroyQueue.push action.branch
			@processAction action
		triggerAction: (actionType, branch, attributes, options = {}) ->
			clearTimeout @savingQueueTimeout
			action = Action.buildAction.apply(@, arguments)
			if action.destroy
				@queueDestroy action
				@startSavingQueueTimeout()
			else
				@queueAction action
				@processActionQueue()
			# @queueSaving attributes, branch

		processActionQueue: ->
			return if @processingActions
			@processingActions = true
			do rec = (action = @actionQueue.shift()) =>
				return if not action?
				# action.branch.set action.attributes
				@processAction action				
				@validationQueue.push action
				# console.log "validationQueue", @validationQueue
				rec @actionQueue.shift()
			@processingActions = false
			@startSavingQueueTimeout()
		processAction: (action) ->
			action.compound()
			action.addToHistory()
			action.triggerNotification()
			action.branch.set action.attributes unless not action.attributes?
			App.OfflineAccess.addChange action.branch unless action.options.noLocalStorage

		validate: (branch, attributes, options) ->
			if (val = branch.validation attributes)?
				# console.log val
				false
			else
				true

		startSavingQueueTimeout: ->
			@savingQueueTimeout = setTimeout @processSavingQueue.bind(@), 5000
		processSavingQueue: () ->
			valid = true
			savingQueue = []
			# console.log "Complete validation Queue"
			# _.each @validationQueue, (v) ->
			# 	console.log v.branch.get('guid'), v.branch.id, "Sent attributes", v.attributes, "branch attributes", v.branch.attributes
			@validationQueue = @trimValidQueue @validationQueue
			# console.log "Trimed validation queue", @validationQueue
			# console.log "validation queue", @validationQueue
			do rec = (branch = @validationQueue.shift()) =>
				return if not branch? or not valid
				# console.log "Validation", branch.get('guid'), branch.id, branch.attributes
				if not @validate branch, branch.attributes
					return valid = false
				savingQueue.push branch
				# console.log branch.get('guid'), "validated"
				rec @validationQueue.shift()
			if valid then @acceptChanges(savingQueue) else @rejectChanges(savingQueue)

		rejectChanges: (validQueue) ->
			@validationQueue = []
			App.Note.noteController.reset()
			App.OfflineAccess.clearCached()
			App.Notify.alert 'brokenTree', 'danger'
		processDestroy: ->
			# console.log "destroyQueue", @destroyQueue
			do rec = (branch = @destroyQueue.shift()) =>
				return if not branch?
				if branch.id?
					branch.destroy()				
				rec @destroyQueue.shift()
		acceptChanges: (validQueue) ->
			# console.log "accept changes", validQueue
			@processDestroy()
			App.Notify.alert 'saving', 'save'
			# console.log "trimed changes", validQueue
			do rec = (branch = validQueue.shift()) ->
				return if not branch?
				branch.save()
				rec validQueue.shift()
			App.OfflineAccess.clearCached()
			App.Notify.alert 'saved', 'save'
		getDestroyGuids: ->
			guids = []
			_.each @destroyQueue, (toDestroy) ->
				guids.push toDestroy.guid
		trimValidQueue: (validQueue) ->
			guids = []
			queue = []
			_.each validQueue, (obj) =>
				if obj.branch.get('guid') not in guids and obj.branch not in @destroyQueue
					guids.push obj.branch.get('guid')
					queue.push obj.branch
			queue
