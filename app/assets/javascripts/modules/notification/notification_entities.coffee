@Notable.module "Notify", (Notify, App, Backbone, Marionette, $, _) ->
	# Notify Documentation
	# Use anywhere in JavaScript by calling:
	#   App.Notify.alert message, type, {options}
	# Options include:
	#   selfDestruct: [boolean]
	#   destructTime: [time in ms]  // time until it is destroyed
	#   retryTime: [integer] // time until sync will be perfomed again
	#   dynamicText: [string] // variable string for custom descriptions
	# For example:
	#   App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false}

	class Notify.Alerts extends Backbone.Collection
		model: Notify.Alert

	class Notify.Alert extends Backbone.Model
		defaults:
			notificationType: 'save-notification'
			notificationMessage: ''
			selfDestruct: true
			destructTime: 7000

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
		loading: "<i>loading ...</i>"
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
		connectionRetry: "Trying to reconnect in 10 seconds."
		connectionAttempt: "Will continue trying to reconnect every two minutes."
		connectionFound: "We're back online!"
		# Notebook
		needsNotebook: "Your account needs to have at least one notebook."
		newNotebook: "A new notebook has been created!"
		deleteNotebook: "Notebook deleted. <a class='undo-notebook-delete'> undo </a>"
		preventNotebook: "Sorry, working with notebooks while offline is currently not possible."
		# Modviews
		outlineModview: "Outline view activated."
		mindmapModview: "Mindmap view activated. <i>(still in active development)</i>"
		gridModview: "Grid view is not yet operational."

		# Import/Export
		exceedPasting: "Pasting limit exceeded. Let us know if you really need to simultaneously paste more than 100 notes."
		exportPlain: "Your notes are ready for export in plain text format."
		exportParagraph: "Your notes are ready for export in paragraph form."
		brokenTree: "Sorry, something just broke. Your notebook will attempt to reset in a few seconds."

		#Leaves
		attachError: "There was an error attaching the file to your note."
		attachSuccess: "Great job! You successfully attached the file to your note."
		attachUpdate: "You successfully updated the file on this note."

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
		if options.dynamicText?
			attributes.notificationMessage = _customMessage(options.dynamicText, message)
		_.defaults options, attributes

	_customMessage = (variable, message) ->
		switch message
			when "connectionRetry" then "Trying to reconnect in #{variable} seconds."
			when "evernoteRateLimit" then "Evernote usage has been temporarily exceeded. Please try again in #{Math.floor(variable/60)+1} minutes. <a href='learn#limits'>Learn More</a>"
			when "attachSuccess" then "Great job! You successfully attached the #{variable} to your note."
			when "attachUpdate" then "You successfully updated the #{variable} on this note."
			else "Something went wrong, please try again later."

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