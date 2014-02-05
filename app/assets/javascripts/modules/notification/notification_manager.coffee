@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->
	# Notify Documentation
		# Use anywhere in JavaScript by calling:
		#   App.Notify.alert message, type, {options}
		# Options include:
		#   selfDestruct: [boolean]
		#   destructTime: [time in ms]  // time until it is destroyed
		#   retryTime: [integer] // time until sync will be perfomed again
		# For example:
		#   App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false}

	# Private Variables and Settings
	@_notificationTimeOut = 7000
	@_fadeOutTime = 400

	_notificationTypes =
		success: 'success-notification' # green
		warning: 'warning-notification' #yellow
		danger: 'danger-notification' #red
		save: 'save-notification'

	_notificationMessages =
		saving: "<i>saving...</i>"
		saved: "Changes saved."
		syncing: "<i>connecting to Notable ... </i>"
		synced: "Connected."
		deleteNote: "Note deleted. <a class='undo-note-delete'> undo </a>"
		undo: "Change undone."
		newNote: "New note has been added."
		# Evernote
		evernoteConnect: "Successfully connected your Notable account to Evernote!
			<a href='learn'>Learn More</a>"
		evernoteSync: "Your Notable account has been synced to Evernote.
			<a href='learn'>Learn More</a>"
		evernoteError: "There was an error connecting your Notable account to Evernote.
			<a href='learn'>Learn More</a>"
		evernoteRateLimit: "Evernote usage has been temporarily exceeded.
			<a href='learn'>Learn More</a>"
		# Internet
		connectionLost: "Connection has been lost."
		connectionAttempt: "Trying to reconnect in 10 seconds."
		connectionFound: "We're back online!"
		# Notebook
		needsNotebook: "Your account needs to have at least one notebook."
		newNotebook: "A new notebook has been created!"
		deleteNotebook: "Notebook deleted. <a class='undo-notebook-delete'> undo </a>"
		# Import/Export
		exceedPasting: "Pasting limit exceeded. Let us know if you really need to simultaneously paste more than 100 notes."
		exportPlain: "Your notes are ready for export in plain text format."
		exportParagraph: "Your notes are ready for export in paragraph form."
		brokenTree: "Sorry, something just broke. Your notebook was reset to its latest stable state."

	@alert = (message, type, options) ->
		throw "invalid notification message" unless _notificationMessages[message]?
		throw "invalid notification type" unless _notificationTypes[type]?
		if type is 'save' then return _insertSaveNotification(message)
		_renderNotification _buildNotificationAttributes(message, type, options)

	_buildNotificationAttributes = (message, type, options = {}) ->
		attributes =
			notificationType: _notificationTypes[type]
			notificationMessage: _notificationMessages[message]
			selfDestruct: true
			destructTime: Notify._notificationTimeOut
		if options.retryTime?
			attributes.notificationMessage = _customMessage(options.retryTime, message)
		_.defaults options, attributes

	_customMessage = (retryTime, message) ->
		switch message
			when "connectionAttempt" then "Trying to reconnect in #{retryTime} seconds."
			when "evernoteRateLimit" then "Evernote usage has been temporarily exceeded. Please try again in #{Math.floor(retryTime/60)+1} minutes."
			else "Try again in #{retryTime} minutes."

	# Save notification region
	_timeoutID = null
	_insertSaveNotification = (message) ->
		clearTimeout _timeoutID
		$('.save-notification').html("<div> #{ _notificationMessages[message]} </div>").show()
		_timeoutID = setTimeout (=>$('.save-notification').first().fadeOut(Notify._fadeOutTime)), 3000

	_renderNotification = (notificationAttributes) ->
		Notify.alerts.reset()
		Notify.alerts.add new Notify.Alert notificationAttributes

	# _renderStackedAlerts = (notificationAttributes) ->
	# 	Notify.alerts.add new Notify.Alert notificationAttributes

)
