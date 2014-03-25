@Notable.module("User", (User, App, Backbone, Marionette, $, _) ->

	App.User.on "start", ->
		return if window.location.pathname != "/edit"
		options = User.settings.get()
		User.settings.populate(options)
		User.settings.save()

	User.settings =
		get: ->
			defaultSettings =
				shortcut: false
				theme: false
				laytech: false
			return JSON.parse(window.localStorage.getItem("settings")) ? defaultSettings
		populate: (options) ->
			for setting, state of options
				selector = "."+setting+".option"
				$(selector).prop('checked',state)
		save: ->
			$('.save-changes').click (e) ->
				options = {}
				$("input[type='checkbox']").each (option) ->
					setting = App.Helper.ieShim.classList(@)[0]
					state = @.checked
					options[setting] = state
					return
				window.localStorage.setItem "settings", JSON.stringify(options)
				alert "Your changes have been successfully saved."
		shortcutToolbar: ->
			return unless options = JSON.parse(window.localStorage.getItem("settings"))
			if options["shortcut"] is true then $("#shortcuts").show() else $("#shortcuts").hide()
)