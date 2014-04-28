@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	class Action.Transporter

		constructor: () ->
			@storage = new Action.Storage
			@removed = []
			@backoffTimeoutID = -1
			@backoffCount = 0
			@MAX_BACKOFF = 140000 # 2 mins 20 secs

		testServerConnection: (forceBackoff = false) ->
			App.Note.allNotesByDepth.fetch
				data: notebook_id: App.Notebook.activeTrunk.id
				success: =>
					@startSync()
				error: =>
					@notifyFailure forceBackoff
		notifyFailure: (forceBackoff) ->
			timeToRetry = Action.Helpers.fibonacci(@backoffCount)
			console.log timeToRetry
			if timeToRetry < 5 							# 1,1,2,3
				App.Notify.alert 'connectionLost', 'danger', {destructTime: 14000}
			else if timeToRetry < 140 			# 5,8,13,21,34,55,89
				App.Notify.alert 'connectionRetry', 'danger', {retryTime: timeToRetry}
			else														# 144
				App.Notify.alert 'connectionAttempt', 'danger'
			@backoff() if @isOnline() or forceBackoff

		# ------------ Back off methods ------------

		backoff: ->
			@backoffTimeoutID = setTimeout =>
	 			@testServerConnection true
			, @backoffTime()
			++@backoffCount
		backoffTime: ->
			time = Action.Helpers.fibonacci(@backoffCount) * 1000
			if time < @MAX_BACKOFF then time else @MAX_BACKOFF
		clearBackoff: (clearCount = false) ->
			clearTimeout @backoffTimeoutID
			@backoffTimeoutID = null
			@backoffCount = 0 if clearCount

		isOffline: ->
			@backoffTimeoutID?
		isOnline: ->
			!@isOffline()

		# -------------- Syncing with server ----------------

		selectNotification: ->
			syncingNotification = [['syncing', 'warning'], ['synced', 'success']]
			savingNotification = [['saving', 'save'], ['saved', 'save']]
			@notificationToTrigger = if @isOffline() then syncingNotification else savingNotification
		startSync: ->
			@selectNotification()
			App.Notify.alert 'saved', 'save' unless @storage.hasChangesToSync() or @isOffline()
			@clearBackoff true
			if @storage.hasChangesToSync()
				App.Notify.alert.apply(App.Notify.alert, @notificationToTrigger[0])
				@storage.swapToSync()
				@syncActions()
			App.Note.eventManager.trigger 'syncingDone'
			App.Note.syncingCompleted.resolve()
		syncActions: ->
			deleteGuids = @storage.collectDeletes()
			changeGuids = @storage.collectChanges()
			_.each deleteGuids, (guid) => @syncDelete(guid)
			_.each changeGuids, (guid) => @syncChange(guid)

		syncDelete: (guid) ->
			branch = App.Note.allNotesByDepth.findWhere {guid: guid}
			options =	destroy: true, noLocalStorage: true
			@removed.push branch if branch?
			App.Note.allNotesByDepth.remove branch, options if branch?
		syncChange: (guid) ->
			return if @storage.isAlreadyInDeletes guid
			branch = App.Note.allNotesByDepth.findWhere {guid: guid}
			if not branch?
 				branch = new App.Note.Branch()
				App.Note.allNotesByDepth.add branch
			attributes = @storage.getChanges(guid)
			options = noLocalStorage: true
			Backbone.Model.prototype.set.call(branch, attributes, options)

		addToStorage: (action) ->
			if action.destroy
				@storage.addDelete action.branch
			else
				@storage.addChange action.branch

		# Returns an option.success method that will trigger the notification
		# only when all saves have been processed
		successNotification: (callback) ->
			# gets rid of branches that got deleted but never actually got saved to server
			@removed = _.filter @removed, (branch) -> branch.id?
			numberOfChanges = @removed.length + @storage.collectChanges().length
			showNotification = =>
				i = 0
				return =>
					if ++i is numberOfChanges
						App.Notify.alert.apply(App.Notify.alert, @notificationToTrigger[1])
						@storage.clearSyncing()
						@removed = []
						callback() if callback?
			options = success: showNotification()
		processToServer: (callback) ->
			options = @successNotification callback
			changeGuids = @storage.collectChanges()
			_.each changeGuids, (guid) =>
				branch = App.Note.allNotesByDepth.findWhere(guid: guid);
				if branch?
					branch.save null, options
				else
					options.success()
			_.each @removed, (branch) -> branch.destroy(options)
