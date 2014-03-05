@Notable.module "Helpers", (Helpers, App, Backbone, Marionette, $, _) ->

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
			matches = Helpers.collectAllMatches text
			matches = matches.concat Helpers.collectAllMatches text, Helpers.tagRegex.matchHtmlEntities, 1
			matches = matches.sort (a,b) -> a.index - b.index
		increaseOffsetAdjustment: ->
			args = App.Note.concatWithArgs arguments, @addAdjustment
			@adjustOffset.apply this, args
		decreaseOffsetAdjustment: ->
			args = App.Note.concatWithArgs arguments, @substractAdjustment
			@adjustOffset.apply this, args
		adjustOffset: (matches, previousOffset, adjustmentOperator = @addAdjustment) ->
			adjustment = matches.reduce adjustmentOperator(previousOffset), 0
			previousOffset + adjustment
		adjustAnchorOffset: (sel, title) ->
			return false unless (parent = @getContentEditable sel)?
			matches = @collectMatches parent.innerHTML
			textBefore = @buildTextBefore parent, sel
			@adjustOffset matches, textBefore.length
		addAdjustment: (previousOffset) -> (acc, match) ->
			if (acc + previousOffset > match.index) then acc + match.adjustment
			else acc
		substractAdjustment: (previousOffset) -> (acc, match) ->
			acc - match.adjustment

		textBeforeCursor: (sel, title) ->
			return false unless sel.baseNode?
			offset = @adjustAnchorOffset(sel, title)
			textBefore = title.slice(0,offset)
		textAfterCursor: (sel, title) ->
			return false unless sel.baseNode?
			offset = @adjustAnchorOffset(sel, title)
			textAfter = title.slice offset
			textAfter = "" if Helpers.tagRegex.matchTagsEndOfString.test(textAfter)
			textAfter
		isEmptyAfterCursor: ->
			@textAfterCursor.apply(this, arguments).length is 0
		isEmptyBeforeCursor: ->
			@textBeforeCursor.apply(this, arguments).length is 0

	Helpers.collectAllMatches = (title, regex = Helpers.tagRegex.matchTag, adjustment = 0) ->
		matches = []
		while match = regex.exec title
			matches.push
				match: match[0]
				index: match.index
				input: match.input
				adjustment: match[0].length - adjustment
		matches

	Helpers.tagRegex =
		matchTag: /<(.+?)>/g
		matchTagsEndOfString: /^(<\/?[a-z]+>)+$/
		matchHtmlEntities: /&[a-z]{2,4};/g
		matchEmptyTag: /<[a-z]+><\/[a-z]+>/g
		trimEmptyTags: (text) ->
			text.replace(Helpers.matchEmptyTag, "")
