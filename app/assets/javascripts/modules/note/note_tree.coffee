@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	# class Note.child extends Note.Branch
	class Note.Collection extends Backbone.Collection
		model: Note.Branch
		url:'/notes'

		comparator: (note1, note2) ->
			if note1.get('depth') is note2.get('depth')
				order = note1.get('rank') - note2.get('rank')
			else
				order = note1.get('depth') - note2.get('depth')

	class Note.Tree extends Backbone.Collection
		model: Note.Branch
		url:'/notes'


		# Manage note insertion in the nested structure
		add: (note, options) ->
			collectionToAddTo = @getCollection note.get 'parent_id'
			Backbone.Collection.prototype.add.call(collectionToAddTo, note, options)
		insertInTree: (note, options) ->
			@add note, options
			newCollection = @getCollection note.get 'parent_id'
			if note.get('rank') < newCollection.length
				@increaseRankOfFollowing note
			if note.descendants.length isnt 0
				firstDescendantDepth = note.firstDescendant().get('depth')
				depthDifference = note.get('depth') - firstDescendantDepth + 1
				if depthDifference isnt 0
					note.increaseDescendantsDepth depthDifference
			newCollection.sort()
		removeFromCollection: (collection, note) ->
			collection.remove note
			@decreaseRankOfFollowing note

		createNote: (noteCreatedFrom, textBefore, textAfter) ->
			textAfter = Note.prependStyling(textAfter)
			hashMap = @dispatchCreation.apply @, arguments
			newNote = new Note.Branch
			newNote.addUndoCreate()
			newNoteAttributes = Note.Branch.generateAttributes hashMap.createBeforeNote, hashMap.newNoteTitle
			if hashMap.rankAdjustment then newNoteAttributes.rank += 1
			newNote.save newNoteAttributes
			@insertInTree newNote
			hashMap.setFocusIn ||= newNote
			[newNote, hashMap.oldNoteNewTitle, hashMap.setFocusIn]
		dispatchCreation: (noteCreatedFrom, textBefore, textAfter) ->
			if textBefore.length is 0
				@createBefore.apply(@, arguments)
			else
				@createAfter.apply(@, arguments)
		createAfter: (noteCreatedFrom, textBefore, textAfter) ->
			createFrom = @findFollowingNote noteCreatedFrom
			rankAdjustment = false
			if not createFrom or createFrom.get('depth') < noteCreatedFrom.get('depth')
				createFrom = noteCreatedFrom
				rankAdjustment = true
			createBeforeNote: createFrom
			newNoteTitle: textAfter
			rankAdjustment: rankAdjustment
			oldNoteNewTitle: textBefore
		createBefore:  (noteCreatedFrom, textBefore, textAfter) ->
			createBeforeNote: noteCreatedFrom
			newNoteTitle: textBefore
			oldNoteNewTitle: textAfter
			setFocusIn: noteCreatedFrom
		deleteNote: (note, isUndo) -> #ignore isUndo unless dealing with action manager!
			if not isUndo then note.addUndoDelete()
			descendants = note.getCompleteDescendantList()
			_.each descendants, (descendant) ->
				descendant.destroy()
			note.destroy success: (self) => @decreaseRankOfFollowing self

		# Returns the descendants of matching parent_id
		getCollection: (parent_id) ->
			if parent_id is 'root' or parent_id is undefined then @
			else @getDescendantCollection parent_id
		getDescendantCollection: (pid) ->
			@findNote(pid).descendants
		findInCollection: (searchHash) ->
			@where searchHash
		findFirstInCollection: (searchHash) ->
			@findWhere searchHash

		# Search the whole tree recursively but top level
		# Returns the element maching id and throws error if this fails
		findNote: (guid) ->
			searchedNote = false
			searchRecursively = (currentNote, rest) ->
				return searchedNote if searchedNote or !currentNote?
				if currentNote.get('guid') is guid
					return searchedNote = currentNote
				searchRecursively _.first(rest), _.rest rest
				if currentNote.descendants.length isnt 0 and not searchedNote
					searchRecursively currentNote.descendants.first(), currentNote.descendants.rest()
			searchRecursively @first(), @rest() # start search
			throw "#{guid} not found. Aborting" unless searchedNote
			searchedNote

		getNote: (guid) -> @findNote(guid) # alias

		# findByGuidInCollection: (guid) ->
		# 	noteSearched = false
		# 	@every (note) ->
		# 		if note.get('guid') is guid
		# 			noteSearched = note
		# 			false # break
		# 		else
		# 			true # continue
		# 	noteSearched

		modifySiblings: (parent_id, modifierFunction, filterFunction = false) ->
			siblingNotes = @getCollection parent_id
			if filterFunction
				siblingNotes	= siblingNotes.filter filterFunction
			_.each siblingNotes, modifierFunction, this

		filterPrecedingNotes: (self) ->
			(comparingNote) ->
				self.get('rank') >= comparingNote.get('rank') and
				self.get('guid') isnt comparingNote.get('guid')
		filterFollowingNotes: (self) ->
			(comparingNote) ->
				self.get('rank') <= comparingNote.get('rank') and
				self.get('guid') isnt comparingNote.get('guid')
		modifyRankOfFollowing: (self, modifierFunction) ->
			findFollowing = @filterFollowingNotes(self)
			@modifySiblings self.get('parent_id'), modifierFunction, findFollowing
		increaseRankOfFollowing: (self) ->
			@modifyRankOfFollowing self, Note.increaseRankOfNote
		decreaseRankOfFollowing: (self) ->
			@modifyRankOfFollowing self, Note.decreaseRankOfNote

		findPrecedingInCollection: (note) ->
			currentCollection = @getCollection note.get 'parent_id'
			currentCollection.findFirstInCollection rank: note.get('rank') - 1
		findPreviousNote: (note, searchDescendants = true) ->
			return undefined if (note.isARoot() and note.get('rank') is 1)
			if note.get('rank') is 1
				return @getNote(note.get('parent_id'))
			previousNote = @findPrecedingInCollection note
			if previousNote.descendants.length is 0 or not searchDescendants
				return previousNote
			previousNote.getLastDescendant()
		findFollowingInCollection: (note) ->
			currentCollection = @getCollection note.get 'parent_id'
			currentCollection.findFirstInCollection rank: note.get('rank') + 1
		findFollowingNote: (note, checkDescendants = true) ->
			return note.firstDescendant() if checkDescendants and note.descendants.length isnt 0
			followingNote = undefined
			findFollowingRecursively = (note) =>
				if !(followingNote = @findFollowingInCollection note)? and
					 note.get('parent_id') is 'root'
					return undefined
				return followingNote unless !followingNote?
				findFollowingRecursively @getNote note.get 'parent_id'
			findFollowingRecursively note
			followingNote
		jumpNoteUpInCollection: (note) ->
			return undefined unless note.get('rank') > 1
			previousNote = @findPrecedingInCollection note
			note.decreaseRank()
			previousNote.increaseRank()
			@getCollection(note.get 'parent_id').sort()
		jumpNoteDownInCollection: (note) ->
			followingNote = @findFollowingInCollection note
			return undefined unless followingNote?
			followingNote.decreaseRank()
			note.increaseRank()
			@getCollection(note.get 'parent_id').sort()

		getRoot: (branch) ->
			return branch if branch.isARoot(true)
			@getRoot @findNote branch.get('parent_id')
		buildBranchLike: (attributes) ->
			attributes: attributes
			get: (attr) -> @attributes[attr]

		findPrecedingBranch: (branch, precedingBranch) ->
			return precedingBranch if precedingBranch? or branch.isFirstRoot(true)
			ancestorBranch = @findNote branch.get('parent_id')
			precedingBranch = @findPrecedingInCollection ancestorBranch
			@findPrecedingBranch(ancestorBranch, precedingBranch)
		getJumpPositionUpTarget: (branch) ->
			# rootAncestor = @getRoot branch
			# precedingBranch = @findPrecedingInCollection rootAncestor
			return false if not precedingBranch = @findPrecedingBranch branch
			preceding = precedingBranch.descendants.last()
			return @buildBranchLike(rank: 0, depth: precedingBranch.get('depth') + 1, parent_id: precedingBranch.get('guid')) if not preceding?
			jumpTarget = @getJumpPositionTarget @jumpUpTarget(), branch.get('depth'), preceding.getCompleteDescendantList()
			@makeDescendant(preceding, branch.get('depth'),
					jumpTarget || @buildBranchLike rank: preceding.get('rank'), depth: preceding.get('depth'), parent_id: preceding.get('parent_id'))
		makeDescendant: (preceding, depth, jumpTarget) ->
			return jumpTarget if depth - 1 < jumpTarget.get('depth')
			@buildBranchLike rank: 0, depth: jumpTarget.get('depth') + 1, parent_id: jumpTarget.get('guid') || preceding.get('guid')
		# isAccessibleDepth: (jumpTarget) ->
		jumpTarget: (actionType) -> (depth, descendantList) ->
			action =
				jumpUp: "last"
				jumpDown: "first"
			_[action[actionType]] _.filter descendantList, (descendant) ->
				descendant.get('depth') is depth
		jumpUpTarget: ->
			@jumpTarget("jumpUp").bind @
		jumpDownTarget: ->
			@jumpTarget("jumpDown").bind @
		getJumpPositionTarget: (getJumpTarget, depth, descendantList, target) ->
			do rec = (depth, target) ->
				return target if target?
				return false if depth is 0
				rec depth - 1, getJumpTarget depth, descendantList
		newJumpUp: (branch) ->
			return false if not target = @getJumpPositionUpTarget branch
			target
		jumpToTarget: (branch, target, modifier = 0) ->
			branch.cloneAttributes target, rank: target.get('rank') + modifier
		jumpToTargetUp: (branch, target) ->
			@jumpToTarget branch, target, 1
		jumpPositionUp: (note) ->
			previousNote = @findPreviousNote note, false
			return note if not previousNote?
			if note.isInSameCollection previousNote
				@jumpNoteUpInCollection note
			# else if (depthDifference = previousNote.get('depth') - note.get('depth')) > 0
			# 	@tabNote note, @getNote previousNote.get 'parent_id'
			else
				previousCollection = @getCollection note.get 'parent_id'
				return note if not target = @newJumpUp note
				@removeFromCollection previousCollection, note
				@jumpToTargetUp(note, target)
				@insertInTree note
				note

		getJumpPositionDownTarget: (branch, followingBranch) ->
			following = followingBranch.descendants.first()
			return @buildBranchLike(rank: 1, depth: followingBranch.get('depth') + 1, parent_id: followingBranch.get('guid')) if not following?
			jumpTarget = @getJumpPositionTarget @jumpDownTarget(), branch.get('depth'), following.getCompleteDescendantList()
			@makeDescendant(following, branch.get('depth'),
					jumpTarget || @buildBranchLike rank: following.get('rank'), depth: following.get('depth'), parent_id: following.get('parent_id'))
		newJumpDown: (branch, followingBranch) ->
			return false if not target = @getJumpPositionDownTarget branch, followingBranch
			target
		jumpToTargetDown: (branch, target) ->
			modifier = 0
			if target.get('rank') is 0 then modifier = 1
			@jumpToTarget branch, target, modifier
		jumpPositionDown: (branch) ->
			followingBranch = @findFollowingNote branch, false
			return false if not followingBranch?
			if branch.isInSameCollection followingBranch
				@jumpNoteDownInCollection branch
			else
				# depthDifference = note.get('depth') - followingNote.get('depth')
				# @unTabNote note, followingNote
				previousBranch = @getCollection branch.get 'parent_id'
				return branch if not target = @newJumpDown branch, followingBranch
				@removeFromCollection previousBranch, branch
				@jumpToTargetDown branch, target
				@insertInTree branch
			branch

		jumpFocusDown: (note) ->
			return followingNote if (followingNote = @findFollowingNote note)?
		jumpFocusUp: (note) ->
			return previousNote if (previousNote = @findPreviousNote note)?

		tabNote: (note, parent = @findPrecedingInCollection note) ->
			return false unless note.get('rank') > 1
			note.addUndoMove()
			previousParentCollection = @getCollection note.get 'parent_id'
			@removeFromCollection previousParentCollection, note
			note.save
				parent_id: parent.get 'guid'
				rank: parent.descendants.length + 1
				depth: 1 + parent.get 'depth'
			@insertInTree note
		unTabNote: (note, followingNote = false) ->
			return false if note.isARoot()
			note.addUndoMove()
			previousParent = @getNote note.get 'parent_id'
			@removeFromCollection previousParent.descendants, note
			@generateNewUnTabAttributes note, followingNote, previousParent
			@insertInTree note
		generateNewUnTabAttributes: (note, followingNote, previousParent) ->
			if followingNote
				note.cloneAttributes followingNote
			else
				note.save
					parent_id: previousParent.get('parent_id')
					rank: previousParent.get('rank') + 1
					depth: note.get('depth') - 1

		setDropAfter: (dragged, dropAfter) ->
			dragged.save
				parent_id: dropAfter.get('parent_id')
				rank:  dropAfter.get('rank') + 1
				depth: dropAfter.get('depth')
		setDropBefore: (dragged, dropBefore) ->
			dragged.cloneAttributes dropBefore
		dropMoveGeneral: (dropMethod) -> (dragged, draggedInto) =>
			branchToRemoveFrom = @getCollection dragged.get('parent_id')
			@removeFromCollection(branchToRemoveFrom, dragged)
			dropMethod(dragged, draggedInto)
			@insertInTree dragged
		dropBefore: (dragged, dropBefore) ->
			(@dropMoveGeneral @setDropBefore.bind @).call(this, dragged, dropBefore)
		dropAfter:(dragged, dropAfter) ->
			(@dropMoveGeneral @setDropAfter.bind @).call(this, dragged, dropAfter)

		mergeWithPreceding: (note) ->
			if note.get('title').length isnt 0
				return false if note.hasDescendants()
				preceding = @findPreviousNote note
				return false if preceding.get('depth') > note.get('depth')
			else
				preceding = @findPreviousNote note
			title = preceding.get('title') + note.get('title')
			@deleteNote note
			[preceding, title]
		comparator: (note) ->
			note.get 'rank'

)
