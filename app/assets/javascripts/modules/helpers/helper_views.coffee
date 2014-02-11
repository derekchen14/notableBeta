@Notable.module "Helper", (Helper, App, Backbone, Marionette, $, _) ->

	Helper.eventManager = _.extend {}, Backbone.Events

	Helper.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@eventManager = Helper.eventManager
			@progressView = new App.Helper.ProgressView
			@setEvents()
			@userIdle = false
		setEvents: ->
			@eventManager.on "showProgress", @showProgress, @
			@eventManager.on "pushProgress", @progressView.pushProgress, @progressView
			@eventManager.on "intervalProgress", @progressView.intervalProgress, @progressView
			@eventManager.on "showChrome", @showChrome, @
			@eventManager.on "hideChrome", @hideChrome, @

		showProgress: ->
			App.contentRegion.currentView.treeRegion.close()
			App.contentRegion.currentView.crownRegion.close()
			@progressView.resetProgress()
			App.contentRegion.currentView.treeRegion.show @progressView

		showChrome: ->
			$("#modview-region, #links, nav .navbar-header").show()
			$(".uv-icon, .icon-feats-delete").show()
			$("#message-center .message-template").css("opacity", "1")
			$(".navbar-nav, .navbar-search").removeClass("hidden")
			$("#crown, #tree").css("border-color", "#EAEAEA")
			$("body, nav").css("background-color", "#EAEAEA")
			$("body").css("background-image", "url(/assets/satinweave.png)")
			$(".feats").css("color", "#3D3D3D")
			$("#content-template h3").css("color", "#989898")
			$("#content-template .breadcrumb>li.root-breadcrumb a").css("color", "#989898")
			$("nav").css(
				"background": "-moz-linear-gradient(top, #fdfdfd 0%, #cccccc 100%)"
				"background": "-webkit-gradient(linear, left top, left bottom, color-stop(0%, #fdfdfd), color-stop(100%, #cccccc))"
				"background": "-webkit-linear-gradient(top, #fdfdfd 0%, #cccccc 100%)"
				"background": "-ms-linear-gradient(top, #fdfdfd 0%, #cccccc 100%)"
				"background": "linear-gradient(to bottom, #fdfdfd 0%, #cccccc 100%)"
			)
			$("#content-template").css(
				"background-image": "url(/assets/cardboard_@2X.png)"
				"border-color": "#C1C1C1"
				"box-shadow": "2px 2px 6px 0 rgba(0, 0, 0, 0.15)"
			)
			@userIdle = false
		hideChrome: ->
			$("#modview-region, #links, nav .navbar-header").fadeOut(1000)
			$("#message-center .message-template").css("opacity", "0")
			$(".uv-icon, .icon-feats-delete").fadeOut(600)
			$("body, nav").css("background", "#FDFDFD")
			$("#crown, #tree").css("border-color", "#FDFDFD")
			$("body").css("background-image", "none")
			$(".feats, #content-template h3").css("color", "#FDFDFD")
			$("#content-template").css(
				"background-image": "none"
				"border-color": "#FDFDFD"
				"box-shadow": "none"
			)
			window.setTimeout ->
				$(".navbar-nav, .navbar-search").addClass("hidden")
				$("#content-template .breadcrumb>li.root-breadcrumb a").css("color", "#FDFDFD")
			, 500
			@userIdle = true
		quickHideChrome: ->
			$("#content-template .breadcrumb>li.root-breadcrumb a").css("color", "#FDFDFD")
			$(".feats").css("color", "#FDFDFD")
			$(".icon-feats-delete").hide()
			$("#crown, #tree").css("border-color", "#FDFDFD")

	progressMessages =
		default: "Loading, please wait ..."
		enNotebooks: "Loading notebooks ..."
		enyncing: "Syncing notebooks from Evernote ..."
		mindmapModview: "Loading mindmap view ..."
		gridModview: "Loading grid view ..."
		outlineModview: "Loading outline view ..."

	class Helper.ProgressView extends Marionette.Layout
		template: "helper/progress"
		id: "progress-center"
		tagName: "section"

		resetProgress: ->
			@markProgress(36)
		markProgress: (percent) ->
			$(".progress-bar").css("width", "#{percent}%")
		pushProgress: ->
			return @stopProgress() unless $(".progress").css("width")?
			percent = @calculateProgress()
			if percent < 70
				percent += 21
			else if percent < 100
				percent += 8
			else
			  @stopProgress()
			@markProgress(percent)
		calculateProgress: ->
			op = $(".progress").css("width")
			ip = $(".progress-bar").css("width")
			width = parseInt(ip.slice(0,ip.length-2))/parseInt(op.slice(0,op.length-2))
			Math.round(width*100)
		intervalProgress: ->
			@interval = setInterval =>
				@pushProgress()
			, 1600
		stopProgress: ->
			clearInterval(@interval) if @interval?

	# Initializers -------------------------
	Helper.addInitializer ->
		Helper.controller = new Helper.Controller()
