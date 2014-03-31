@Notable.module("Scaffold", (Scaffold, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Scaffold.startWithParent = false

	class Scaffold.MessageView extends Marionette.Layout
		template: "scaffold/message"
		id: "message-center"
		tagName: "section"
		regions:
			notificationRegion: "#notification-region"
			modviewRegion: "#modview-region"

		events: ->
			"click .sidebar-toggle": "shiftNavbar"
			"click .new-note": "createNote"
			"click .modview-btn": "applyModview"
			"click .outline": "showOutline"
			"click .mindmap": "showMindmap"
			"click .grid": "showGrid"

		createNote: ->
			if App.Note.activeTree.models.length is 0
				if App.Note.activeBranch is 'root'
					newNoteAttrs =
						rank: 1
						title: ""
						notebook_id: App.Notebook.activeTrunk.id
				else
					newNoteAttrs =
						rank: 1
						title: ""
						depth: App.Note.activeBranch.get('depth') + 1
						parent_id: App.Note.activeBranch.get('guid')
						notebook_id: App.Notebook.activeTrunk.id
			else
				lastNote = App.Note.activeTree.last()
				newNoteAttrs =
					depth: lastNote.get('depth')
					parent_id: lastNote.get('parent_id')
					rank: lastNote.get('rank') + 1
					title: ""
					notebook_id: App.Notebook.activeTrunk.id
			newNote = new App.Note.Branch
			App.Action.orchestrator.triggerAction 'createBranch', newNote, newNoteAttrs
			App.Note.eventManager.trigger "render:#{App.Note.activeBranch.get('guid')}" if App.Note.activeBranch isnt "root"
			App.Note.eventManager.trigger "setCursor:#{App.Note.activeTree.last().get('guid')}"
			App.Notify.alert 'newNote','success'
			# mixpanel.track("New Note")
		shiftNavbar: (e) ->
			$(".navbar-header").toggleClass("navbar-shift")
			$(".navbar-right").toggleClass("navbar-shift")
			$(".sidebar-toggle").toggleClass("selected")

		applyModview: (e) ->
			type = App.Helper.ieShim.classList(e.currentTarget)[1]
			$(".modview-btn").removeClass("selected")
			$(".#{type}").addClass("selected")
		showOutline: ->
			App.contentRegion.currentView.treeRegion.close()
			App.contentRegion.currentView.crownRegion.close()
			treeView = new App.Note.TreeView collection: App.Note.activeTree
			App.contentRegion.currentView.treeRegion.show treeView
			App.Notify.alert 'outlineModview','success',
		showMindmap: ->
			App.contentRegion.currentView.treeRegion.close()
			treeModview = new App.Note.TreeModview collection: App.Note.activeTree
			App.contentRegion.currentView.treeRegion.show treeModview
			App.Notify.alert 'mindmapModview','success'
		showGrid: ->
			App.Notify.alert 'gridModview','danger'

	class Scaffold.ContentView extends Marionette.Layout
		template: "scaffold/content"
		id: "content-center"
		tagName: "section"
		regions:
			breadcrumbRegion: "#breadcrumb-region"
			crownRegion: "#crown-region"
			treeRegion: "#tree-region"

		toggleBreadcrumbs: ->
			if $("#breadcrumb-region").html() isnt ""
				@$(".chain-breadcrumb").toggleClass("show-chain")

	class Scaffold.SidebarView extends Marionette.Layout
		template: "scaffold/sidebar"
		tagName:	"section"
		id: "sidebar-center"
		regions:
			notebookRegion: "#notebook-list"
			recentNoteRegion: "#recentNote-region"
			favoriteRegion: "#favorite-region"
			tagRegion: "#tag-region"

		events: ->
			"click h1.sidebar-dropdown": "toggleList"
			"click li": "selectListItem"
			'keypress #new-trunk': 'checkForEnter'
			'click .new-trunk-btn': 'tryCreatingTrunk'

		toggleList: (e) ->
			$(e.currentTarget.nextElementSibling).toggle(400)
			$(e.currentTarget.firstElementChild).toggleClass("closed")
		selectListItem: (e) ->
			liClass = e.currentTarget.className
			if liClass is "note"
				@$('li.'+liClass).removeClass('selected')
				$(e.currentTarget).addClass('selected')
				alert	("These notes are just placeholders.")
			else if liClass is "tag" or liClass is "tag selected"
				@$(e.currentTarget).toggleClass('selected')
				alert	("These tags are just a placeholders.")
		checkForEnter: (e) ->
			@tryCreatingTrunk() if e.which == 13
		tryCreatingTrunk: ->
			online = App.Helper.ConnectionAPI.checkConnection
			$.when(online()).then ( =>
				@createTrunk()
			), ( =>
				@$('#new-trunk').val('')
				App.Notify.alert 'preventNotebook', 'warning', {destructTime: 9000}
				App.Helper.eventManager.trigger "closeSidr"
			)
		createTrunk: ->
			if @$('#new-trunk').val().trim()
				trunk_attributes =
					title: @$('#new-trunk').val().trim()
					modview: "outline"
					guid: App.Note.generateGuid()
					user_id: App.User.activeUser.id
				App.Notebook.forest.create trunk_attributes,
					success: (trunk) ->
						@$('#new-trunk').val('')
						trunk.trigger "created"
			else
				$("#new-trunk").fadeOut().fadeIn().fadeOut().fadeIn(400, ->
					$("#new-trunk").focus()
				)

	class Scaffold.LinksView extends Marionette.Layout
		template: "scaffold/links"
		id: "links-center"
		tagName: "footer"

		events: ->
			"click .close-shortcuts": "closeShortcuts"

		closeShortcuts: ->
			options = App.User.settings.get()
			options["shortcut"] = false
			window.localStorage.setItem "settings", JSON.stringify(options)
			$("#shortcuts").hide()

	# Initializers -------------------------
	App.Scaffold.on "start", ->
		messageView = new App.Scaffold.MessageView
		App.messageRegion.show messageView
		contentView = new App.Scaffold.ContentView
		App.contentRegion.show contentView
		sidebarView = new App.Scaffold.SidebarView
		App.sidebarRegion.show sidebarView

)
