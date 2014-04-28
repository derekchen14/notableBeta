@Notable.module "Leaf", (Leaf, App, Backbone, Marionette, $, _) ->
	class Leaf.AttachView extends Marionette.ItemView
		id: "attach"
		template: "leaf/attach"

		events: ->
			"click .glyphicon-remove": "clearExport"

		initialize: (options) ->
			@model = new Leaf.AttachModel tree: @collection, inParagraph: options.inParagraph, title: options.title
			if options.inParagraph then App.Notify.alert 'exportParagraph', 'success'
			else App.Notify.alert 'exportPlain', 'success'

		clearExport: ->
			App.Note.eventManager.trigger "clear:export"

	class Leaf.AttachModel extends Backbone.Model
		urlRoot : '/attach'

		initialize: ->
			if @get('inParagraph') then @render = @renderTreeParagraph else @render = @renderTree
			# @set 'title', "Fake Title" #Note.activeBranch.get('title')
			@set 'text', @render @get('tree')

		make_spaces: (num, spaces = '') ->
			if num is 0 then return spaces
			@make_spaces(--num, spaces + '&nbsp;&nbsp;')
		renderTree: (tree)->
			text = ""
			indent = 0
			do rec = (current = tree.first(), rest = tree.rest()) =>
				return (--indent; text) if not current?
				text += @make_spaces(indent) + ' - ' + current.get('title') + '<br>'
				if current.descendants.length isnt 0
					++indent
					rec current.descendants.first(), current.descendants.rest()
				rec _.first(rest), _.rest(rest)

		renderTreeParagraph: (tree) ->
			text = ""
			indent = 0
			do rec = (current = tree.first(), rest = tree.rest()) =>
				return (text) if not current?
				text += '<p>' if current.isARoot true
				text += current.get('title') + ' '
				if current.descendants.length isnt 0
					rec current.descendants.first(), current.descendants.rest()
				if current.isARoot(true) then text += '</p>'
				rec _.first(rest), _.rest(rest)
