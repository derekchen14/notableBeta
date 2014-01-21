@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	class Action.Transporter

		constructor: () ->
			@backoffTimeoutID = null
			@backoffCount = 0
			@MAX_BACKOFF = 140000 # 2 mins 20 secs

		testServerConnection: (forceBackoff = false) ->
			App.Note.allNotesByDepth.fetch
				data: notebook_id: App.Notebook.activeTrunk.id
				success: =>
					App.Notify.alert 'connectionFound', 'success' if @isOffline()
					@startSync()
				error: =>
					@notifyFailure forceBackoff
		notifyFailure: (forceBackoff) ->
			App.Notify.alert 'connectionLost', 'danger', {destructTime: 14000, count: @backoffCount}
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
		# >> To remember : Data synced here might not have passed through validation
		#    since the Orchestrator sends data to localStorage before validating
	
		startSync: ->
			if @isOffline() or Action.storage.hasChangesToSync()
				@clearBackoff true
				App.Notify.alert 'syncing', 'warning'
				@syncActions()
			App.Note.syncingCompleted.resolve()
		syncActions: ->
			deleteGuids = @collectDeletes()
			changeGuids = @collectChanges()
			_.each deleteGuids, (guid) => @syncDelete(guid)
			_.each changeGuids, (guid) => @syncChange(guid)
			setTimeout -> # Purposely slow down so we can see 'syncing' notification
				App.Notify.alert 'synced', 'success' if Action.storage.hasChangesToSync()
				Action.storage.clear()
			, 2500

		collectDeletes: ->
			deleteGuids = Object.keys Action.storage.deletes
		collectChanges: ->
			changeGuids = Object.keys Action.storage.changes
		syncDelete: (guid) ->
			branch = App.Note.allNotesByDepth.findWhere {guid: guid}
			options =	destroy: true, noLocalStorage: true
			branch.destroy options if branch?
		syncChange: (guid) ->
			return if Action.storage.isAlreadyInDeletes guid
			branch = App.Note.allNotesByDepth.findWhere {guid: guid}
			if not branch?
 				branch = new App.Note.Branch()
				App.Note.allNotesByDepth.add branch
			attributes = Action.storage.getChanges(guid)
			options = noLocalStorage: true
			Backbone.Model.prototype.save.call(branch, attributes, options)
