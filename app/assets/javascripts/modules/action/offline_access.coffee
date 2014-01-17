@Notable.module("OfflineAccess", (OfflineAccess, App, Backbone, Marionette, $, _) ->

	_backOffTimeoutID = null
	_backOffInterval = 0
	_cachedChanges = 'unsyncedChanges'
	_cachedDeletes = 'unsyncedDeletes'
	_localStorageEnabled = true
	_inMemoryCachedDeletes = {}
	_inMemoryCachedChanges = {}

	# ------------	cached changes & deletes ------------

	_fibonacci = (n) ->
		return 1 if n is 0 or n is 1
		_fibonacci(n-1) + _fibonacci(n-2)

	_addToChangeCache = (attributes) ->
		_inMemoryCachedChanges[attributes.guid] = attributes
		if _localStorageEnabled
			window.localStorage.setItem _cachedChanges, JSON.stringify(_inMemoryCachedChanges)

	_addToDeleteCache = (guid, toDelete = true)->
		if toDelete then _inMemoryCachedDeletes[guid] = toDelete
		else delete _inMemoryCachedDeletes[guid]
		if _localStorageEnabled
			window.localStorage.setItem _cachedDeletes, JSON.stringify(_inMemoryCachedDeletes)

	@clearCached = -> _clearCached()

	_clearCached = ->
		_inMemoryCachedChanges = {}
		_inMemoryCachedDeletes = {}
		window.localStorage.setItem _cachedChanges, JSON.stringify(_inMemoryCachedChanges)
		window.localStorage.setItem _cachedDeletes, JSON.stringify(_inMemoryCachedDeletes)

	_loadCached = ->
		if _localStorageEnabled
			_inMemoryCachedChanges = JSON.parse( window.localStorage.getItem _cachedChanges ) ? {}
			_inMemoryCachedDeletes = JSON.parse( window.localStorage.getItem _cachedDeletes ) ? {}

	@addChangeAndStart = (note, doNotAddToLocal = false) ->
		_addToChangeCache note.getAllAtributes() unless doNotAddToLocal
		_startBackOff()

	@addChange = (note) -> #this guy is for testing!
		_addToChangeCache note.getAllAtributes()

	@addDelete = (note) ->
		_addToDeleteCache note.get('guid')
	@addDeleteAndStart = (note, options = {}) ->
		_addToDeleteCache note.get('guid') unless options.doNotAddToLocal?
		_startBackOff()

	# this is used by action manager.....
	# without it action mananger undo and redos won't workout
	@addToDeleteCache = (guid, toDelete) ->
		_addToDeleteCache guid, toDelete

	# ------------ back off methods ------------

	_startBackOff = (count = _backOffInterval, clearFirst = false) ->
		if clearFirst then _clearBackOff()
		unless _backOffTimeoutID?
			time = _fibonacci(count) * 1000
			_backOffTimeoutID = setTimeout (->
				_startSync ++count
				), time

	_notifyFailureAndBackOff = (count) ->
		App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false}
		if _fibonacci(count) < 140000 then _startBackOff count, true
		else _startBackOff count, true

	_clearBackOff = () ->
		clearTimeout _backOffTimeoutID
		_backOffTimeoutID = null

	@isOffline = ->
		_backOffTimeoutID?

	@informConnectionSuccess = ->
		if _backOffTimeoutID?
			_clearBackOff()
			_startSync()

	# ------------ sync on lost connection: this is the order in which they are called ----------

	# downloads all notes, this is not reflected in DOM
	_startSync = (time = _backOffInterval, callback) ->
		console.log 'trying to sync...'
		App.Notify.alert 'synced', 'save'
		App.Note.allNotesByDepth.fetch
			data: notebook_id: App.Notebook.activeTrunk.id
			success: -> _deleteAndSave Object.keys(_inMemoryCachedDeletes), time, callback
			error: -> _notifyFailureAndBackOff(time)

	# deltes all notes that were deleted to fix server ID references
	_deleteAndSave = (notesToDelete, time, callback) ->
		unless notesToDelete.length > 0
			return _startAllNoteSync time, callback
		noteReference = App.Note.allNotesByDepth.findWhere {guid: notesToDelete.shift()}
		options =
			success: (note)->
				_clearBackOff()
				_deleteAndSave notesToDelete, time, callback
			error: -> _notifyFailureAndBackOff(time)
		options.destroy = true
		options.noLocalStorage = true
		if noteReference? then noteReference.destroy options # App.Action.orchestrator.trigger noteReference, null, options
		else options.success()

	# starts to sync the actual note data, ranks, depth, parent IDs, etc
	_startAllNoteSync = (time, callback) ->
		changeHashGUIDs = Object.keys _inMemoryCachedChanges
		_fullSyncNoAsync changeHashGUIDs, time, callback

	# syncing the actual note data
	_fullSyncNoAsync = (changeHashGUIDs, time, callback) ->
		unless changeHashGUIDs.length > 0
			if OfflineAccess.hasChangesToSync()
				App.Notify.alertOnly 'syncing', 'warning'
			_clearCached()
			if callback? then return callback() else return

		options =
			success: ->
				_clearBackOff()
				_fullSyncNoAsync changeHashGUIDs, time, callback
			error: -> _notifyFailureAndBackOff(time)

		guid = changeHashGUIDs.pop()
		_loadAndSave guid, _inMemoryCachedChanges[guid], options

	_loadAndSave = (guid, attributes, options) ->
		noteReference = App.Note.allNotesByDepth.findWhere {guid: guid}
		if not noteReference? and not _inMemoryCachedDeletes[guid]?
			noteReference = new App.Note.Branch()
			App.Note.allNotesByDepth.add noteReference
		if noteReference?
			Backbone.Model.prototype.save.call(noteReference,attributes,options)
			options.noLocalStorage = true
			# App.Action.orchestrator.triggerAction noteReference, attributes, options
		else
			options.success()

	# ------------	on FIRST LOAD connection only	 ------------

	@checkAndLoadLocal = (buildTreeCallBack) ->
		unless _localStorageEnabled then return buildTreeCallBack()
		_loadCached()
		showSyncedMsg = true if App.OfflineAccess.hasChangesToSync()
		_startSync(null, buildTreeCallBack)
		if showSyncedMsg
			App.Note.initializedTree.then -> App.Notify.alert 'synced', 'success'
	@setLocalStorageEnabled = (localStorageEnabled) ->
		_localStorageEnabled = localStorageEnabled

	@hasChangesToSync = ->
		_.any(_inMemoryCachedDeletes) or _.any(_inMemoryCachedChanges)
)
