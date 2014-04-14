@Notable.module "Helper", (Helper, App, Backbone, Marionette, $, _) ->

	@CursorPositionAPI =
		setRange: (beginNode, beginOffset, endNode, endOffset) ->
			range = document.createRange()
			range.setStart(beginNode, beginOffset)
			range.setEnd(endNode, endOffset)
			range.collapse false
			range
		setRangeFromBeginTo: (beginingNode, node, offset) ->
			@setRange beginingNode, 0, node, offset
		setSelection: (range) ->
			sel = window.getSelection()
			sel.removeAllRanges()
			sel.addRange(range)

		play: ->
			console.log "play"

		setCursor: ($elem, position = false) ->
			if typeof position is "string"
				@setCursorPosition position, $elem[0]
			else if position is true
				@placeCursorAtEnd($elem)
		selectContent: ($elem) ->
			range = document.createRange();
			range.selectNodeContents($elem[0])
			range
		placeCursorAtEnd: ($elem) ->
			range = @selectContent $elem
			range.collapse false
			@setSelection range
		setCursorPosition: (textBefore, parent) ->
			desiredPosition = @findDesiredPosition textBefore
			[node, offset] = @findTargetedNodeAndOffset desiredPosition, parent
			range = @setRangeFromBeginTo parent, node, offset
			@setSelection range
		findDesiredPosition: (textBefore) ->
			matches = @collectMatches textBefore
			offset = textBefore.length
			@decreaseOffsetAdjustment matches, offset
		findTargetedNodeAndOffset: (desiredPosition, parent) ->
			return [parent, 0] if desiredPosition is 0
			it = document.createNodeIterator parent, NodeFilter.SHOW_TEXT, null, false
			offset = 0;
			while n = it.nextNode()
				offset += n.data.length
				if offset >= desiredPosition
					offset = n.data.length - (offset - desiredPosition)
					break
			[n, offset]

		buildTextBefore: (parent, sel) ->
			# The two last param are extra param to comply with IE
			it = document.createNodeIterator parent, NodeFilter.SHOW_TEXT, null, false
			text = ""
			# Firefox uses isEqualNode instead of isSameNode
			sameNodeFn = if sel.focusNode.isSameNode? then "isSameNode" else "isEqualNode"
			while n = it.nextNode()
				# Used if Firefox loses text node focus and focus on .note-content
				# Maybe look into NodeFilter.SHOW_TEXT ?
				break if sel.anchorNode.contentEditable is "true" and sel.anchorOffset is 0
				if n[sameNodeFn](sel.anchorNode)
					text += n.data.slice(0, sel.anchorOffset)
					break
				text += n.data
			text
		getContentEditable: (sel) ->
			do findContentEditable = (node = sel.anchorNode) ->
				return node unless node?
				if node.contentEditable is "true"
					node
				else
					findContentEditable node.parentNode
		collectMatches: (text) ->
			matches = Helper.collectAllMatches text
			matches = matches.concat Helper.collectAllMatches text, Helper.tagRegex.matchHtmlEntities, 1
			matches = matches.concat @checkForLinks text
			matches = matches.sort (a,b) -> a.index - b.index

		# This is necessary because html entities in links counts twice and makes the adjusted offset off
		# Basically, it retrieves all the links containing an ampersand
		# It then finds the index of the &amp; in the link (not in the href, but between both <a></a>)
		# and it sets the adjustment to be negative since we want to substract those matches
		checkForLinks: (title) ->
			matchLink = /(<a href=\"(.*?(&amp;).*?)>)(.*?)<\/a>/g
			matchAmp = /&amp;/g
			matches = []
			while link = matchLink.exec title
				while amp = matchAmp.exec _(link).last()
					matches.push
						match: link[0]
						index: link.index + amp.index + link[1].length
						input: link.input
						adjustment: -1 * amp[0].length + 1
			matches

		adjustAnchorOffset: (sel, title) ->
			return false unless (parent = @getContentEditable sel)?
			matches = @collectMatches parent.innerHTML
			textBefore = @buildTextBefore parent, sel
			@adjustOffset matches, textBefore.length
		increaseOffsetAdjustment: ->
			args = App.Note.concatWithArgs arguments, @addAdjustment
			@adjustOffset.apply this, args
		decreaseOffsetAdjustment: ->
			args = App.Note.concatWithArgs arguments, @substractAdjustment
			@adjustOffset.apply this, args
		addAdjustment: (previousOffset) -> (acc, match) ->
			if (acc + previousOffset > match.index) then acc + match.adjustment
			else acc
		substractAdjustment: (previousOffset) -> (acc, match) ->
			acc - match.adjustment
		adjustOffset: (matches, previousOffset, adjustmentOperator = @addAdjustment) ->
			adjustment = matches.reduce adjustmentOperator(previousOffset), 0
			previousOffset + adjustment

		textBeforeCursor: (sel, title) ->
			return false unless sel.anchorNode?
			offset = @adjustAnchorOffset(sel, title)
			textBefore = title.slice(0,offset)
		textAfterCursor: (sel, title) ->
			return false unless sel.anchorNode?
			offset = @adjustAnchorOffset(sel, title)
			textAfter = title.slice offset
			textAfter = "" if Helper.tagRegex.matchTagsEndOfString.test(textAfter)
			textAfter
		isEmptyAfterCursor: ->
			@textAfterCursor.apply(this, arguments).length is 0
		isEmptyBeforeCursor: ->
			@textBeforeCursor.apply(this, arguments).length is 0

	Helper.collectAllMatches = (title, regex = Helper.tagRegex.matchTag, adjustment = 0) ->
		matches = []
		while match = regex.exec title
			matches.push
				match: match[0]
				index: match.index
				input: match.input
				adjustment: match[0].length - adjustment
		matches

	Helper.tagRegex =
		matchTag: /<(.+?)>/g
		matchTagsEndOfString: /^(<\/?[a-z]+>)+$/
		matchHtmlEntities: /&[a-z]{2,4};/g
		matchEmptyTag: /<[a-z]+><\/[a-z]+>/g
		trimEmptyTags: (text) ->
			text.replace(Helper.matchEmptyTag, "")
