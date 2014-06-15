@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	# class Note.child extends Note.Branch
	class Note.Collection extends Backbone.Collection
		model: Note.Branch
		url:'/notes'

		validateTree: ->
			@sort()
			return unless (firstBranch = @first())?
			throw "first root broken" unless firstBranch.get('rank') is 1 and firstBranch.get('depth') is 0 and firstBranch.get('parent_id') is 'root'
			do rec = (preceding = @first(), rest = @rest()) =>
				current = _.first rest
				return unless current?
				if preceding.get('parent_id') is current.get('parent_id')
					isRankValid = current.get('rank') - 1 is preceding.get('rank')
					if preceding.get('rank') is current.get('rank')
						if current.get('title') is ""
							current.destroy()
							isRankValid = true
						else if preceding.get('title') is ""
							preceding.destroy()
							isRankValid = true
					throw "rank is broken for #{current.get('guid')}" unless isRankValid 
					throw "depth is broken for #{current.get('guid')}" unless current.get('depth') is preceding.get('depth')
				else
					throw "first descendant has not rank 1 for #{current.get('guid')}" unless current.get('rank') is 1
					ancestor = @find (branch) ->
						branch.get('guid') is current.get('parent_id')
					throw "ancestor does not exist for #{current.get('guid')}" unless ancestor?
					throw "depth is not according to ancestor\"s depth for #{current.get('guid')}" unless current.get('depth') - 1 is ancestor.get('depth')
				rec current, _.rest rest
		comparator: (note1, note2) ->
			if note1.get('depth') is note2.get('depth')
				if note1.get('parent_id') is note2.get('parent_id')
					order = note1.get('rank') - note2.get('rank')
				else
					order = if note1.get('parent_id') < note2.get('parent_id') then -1 else 1
			else
				order = note1.get('depth') - note2.get('depth')

	class Note.Tree extends Backbone.Collection
		model: Note.Branch
		url:'/notes'

		initialize: (branch) ->
			@add branch if branch

		# Manage note insertion in the nested structure
		add: (note, options = {}) ->
			collectionToAddTo = @getCollection note.get 'parent_id'
			# options = _.extend({}, options, silent: true)
			Backbone.Collection.prototype.add.call(collectionToAddTo, note, options)
		insertInTree: (note, options = {}) ->
			@add note, options
			newCollection = @getCollection note.get 'parent_id'
			if note.get('rank') < newCollection.length
				@increaseRankOfFollowing note
			if note.descendants.length isnt 0
				firstDescendantDepth = note.firstDescendant().get('depth')
				depthDifference = note.get('depth') - firstDescendantDepth + 1
				if depthDifference isnt 0
					note.increaseDescendantsDepth depthDifference
			newCollection.sort() unless options.silent is true
		removeFromCollection: (collection, note) ->
			collection.remove note
			@decreaseRankOfFollowing note

		createNote: (noteCreatedFrom, textBefore, textAfter, options = {}) ->
			textAfter = Note.prependStyling(textAfter)
			hashMap = @dispatchCreation.apply @, arguments
			newNote = new Note.Branch
			newNoteAttributes = Note.Branch.generateAttributes hashMap.createBeforeNote, hashMap.newNoteTitle
			if hashMap.rankAdjustment then newNoteAttributes.rank += 1
			App.Action.orchestrator.triggerAction 'createBranch', newNote, newNoteAttributes, options
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
		deleteNote: (note, isUndo, actionType = 'deleteBranch') -> #ignore isUndo unless dealing with action manager!
			@removeFromCollection @getCollection(note.get 'parent_id'), note
			descendants = note.getCompleteDescendantList()
			_.each descendants, (descendant) ->
				App.Action.orchestrator.triggerAction actionType, descendant, null, isUndo: true
			App.Action.orchestrator.triggerAction actionType, note, null, isUndo: isUndo

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
		getRoot: (branch) ->
			return branch if branch.isARoot(true)
			@getRoot @findNote branch.get('parent_id')

		# Returns an array of queryAncestry's to build the searchedTree
		getSearchedCollection: (results) ->
			ancestryChains = (buildAncestry result for result in results)
			searchedTree = (dedupeTree chain for chain in ancestryChains)
		buildAncestry: (result) ->
			queryAncestry = []
			queryResult = @findNote result.guid
			addToAncestry(queryResult) ->
				queryAncestry.push(queryResult)
				return if queryResult.isARoot(true);
				addToAncestry @findNote queryResult.get('parent_id')
			queryAncestry
		dedupeTree: (chain) ->
			searchResult = []
			if chain isnt duplicateAncestryChain
				searchResults.push chain
				# remove trees where a descendant is already a queryResult
				# figure out how to handle situation with siblings
			searchResults

		# Search the whole tree recursively but top level
		# Returns the element matching id and throws error if this fails
		findNote: (guid) ->
			searchedNote = false
			return Note.activeBranch if Note.activeBranch isnt 'root' and guid is Note.activeBranch.get('guid')
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

		# will return a list of all branches starting at the current node

		# getAllSubNotes: () ->
		# 	allNotes = []
		# 	_.each @models, (branch)  ->
		# 		allNotes.push(branch)
		# 		allNotes = Array.prototype.concat.call(allNotes, branch.descendants.getAllSubNotes())
		# 	return allNotes


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
			return undefined if note.isFirstRoot()
			if note.get('rank') is 1
				return @getNote(note.get('parent_id'))
			previousNote = @findPrecedingInCollection note
			if previousNote.descendants.length is 0 or previousNote.get('collapsed') or not searchDescendants
				return previousNote
			previousNote.getLastDescendant false
		findFollowingInCollection: (note) ->
			currentCollection = @getCollection note.get 'parent_id'
			currentCollection.findFirstInCollection rank: note.get('rank') + 1
		findFollowingNote: (note, checkDescendants = not note.get('collapsed')) ->
			return note.firstDescendant() if checkDescendants and not note.get('collapsed') and note.descendants.length isnt 0
			followingNote = undefined
			findFollowingRecursively = (note) =>
				if !(followingNote = @findFollowingInCollection note)? and
					 note.isARoot(true)
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
			note.increaseRank()
			followingNote.decreaseRank()
			@getCollection(note.get 'parent_id').sort()

		jumpTarget: (actionType) -> (depth, descendantList) ->
			action =
				jumpUp: _.last.bind _
				jumpDown: _.first.bind _
			action[actionType] _.filter descendantList, (descendant) ->
				descendant.get('depth') is depth
		getFollowingTarget: ->
			@jumpTarget("jumpDown").bind @
		getPrecedingTarget: ->
			@jumpTarget("jumpUp").bind @

		getJumpPositionTarget: (getJumpTarget, depth, descendantList, target) ->
			unless target? and target.get('depth') >= depth - 1
				target = getJumpTarget depth - 1, descendantList
			return false unless target?
			getJumpTarget(depth, target.descendants.models) || Note.buildBranchLike rank: 0, depth: depth, parent_id: target.get 'guid'
		makeDescendant: (preceding, depth, jumpTarget) ->
			return jumpTarget if depth - 1 < jumpTarget.get('depth')
			Note.buildBranchLike rank: 0, depth: jumpTarget.get('depth') + 1, parent_id: jumpTarget.get('guid') || preceding.get('guid')

		jumpToTarget: (branch, target, modifier = 0) ->
			branch.cloneAttributes target, rank: target.get('rank') + modifier
		jumpToTargetUp: (branch, target) ->
			@jumpToTarget branch, target, 1
		jumpToTargetDown: (branch, target, modifier = 0) ->
			if target.get('rank') is 0 then modifier = 1
			@jumpToTarget branch, target, modifier

		findPrecedingBranch: (branch, precedingBranch) ->
			return precedingBranch if precedingBranch? or branch.isFirstRoot(true)
			branch = @findNote(parent_id) if (parent_id = branch.get('parent_id')) isnt 'root'
			precedingBranch = @findPrecedingInCollection branch
			@findPrecedingBranch(branch, precedingBranch)
		getJumpPositionUpTarget: (branch) ->
			targetDepth = branch.get('depth')
			do rec = (branch = branch, jumpTarget = false) =>
				return jumpTarget if jumpTarget
				return false if not precedingBranch = @findPrecedingBranch branch
				descendantList = precedingBranch.getCompleteDescendantList()
				rec precedingBranch, @getJumpPositionTarget @getPrecedingTarget(), targetDepth, descendantList, precedingBranch

		jumpUp: (branch) ->
			return false if not target = @getJumpPositionUpTarget branch
			target
		jumpPositionUp: (note) ->
			previousNote = @findPreviousNote note, false
			return false if not previousNote?
			App.Action.manager.addHistory 'moveBranch', note
			if note.isInSameCollection previousNote
				@jumpNoteUpInCollection note
			else
				previousCollection = @getCollection note.get 'parent_id'
				return note if not target = @jumpUp note
				@removeFromCollection previousCollection, note
				@jumpToTargetUp(note, target)
				@insertInTree note
			@manageCollapsedHierarchy.exec note
			App.User.idle = false # hideChrome only allowed when using keyboard shortcuts
			note

		manageCollapsedHierarchy:
			config: hierarchy: {}
			buildConfig: (branch) ->
				@config.movingBranch = branch
				@resetHierarchy branch
				return false if branch.isARoot true
				do rec = (branch = Note.tree.findNote branch.get 'parent_id') =>
					@config.hierarchy[branch.get('guid')] = branch if branch.get('collapsed') is true
					@expand branch
					return false if branch.isARoot true
					rec Note.tree.findNote branch.get 'parent_id'
			expand: (branch) ->
				branch.trigger "expand" if branch.get('collapsed')
			collapse: (current, toCollapse) ->
				toCollapse.trigger "collapse" unless current.hasInAncestors toCollapse
			execConfig: (branch) ->
				return @resetHierarchy(true) if branch isnt @config.movingBranch
				@collapse branch, toCollapse for guid, toCollapse of @config.hierarchy
			exec: (branch) ->
				@execConfig branch
				@buildConfig branch
			resetHierarchy: (branch) ->
				# Can force reset by passing true instead of a branch
				return @config.hierarchy = {} if branch is true or @config.movingBranch isnt branch
				for guid, branch of @config.hierarchy
					delete @config.hierarchy[guid] unless @config.movingBranch.hasInAncestors branch

		getJumpPositionDownTarget: (branch, followingBranch) ->
			targetDepth = branch.get('depth')
			do rec = (branch = branch, jumpTarget = false) =>
				return jumpTarget if jumpTarget
				return false if not followingBranch = @findFollowingNote branch, false
				descendantList = followingBranch.getCompleteDescendantList()
				rec followingBranch, @getJumpPositionTarget @getFollowingTarget(), targetDepth, descendantList, followingBranch
		jumpDown: (branch, followingBranch) ->
			return false if not target = @getJumpPositionDownTarget branch, followingBranch
			target
		jumpPositionDown: (branch) ->
			followingBranch = @findFollowingNote branch, false
			return false if not followingBranch?
			App.Action.manager.addHistory 'moveBranch', branch
			if branch.isInSameCollection followingBranch
				@jumpNoteDownInCollection branch
			else
				previousBranch = @getCollection branch.get 'parent_id'
				return branch if not target = @jumpDown branch, followingBranch
				@removeFromCollection previousBranch, branch
				@jumpToTargetDown branch, target
				@insertInTree branch
			@manageCollapsedHierarchy.exec branch
			App.User.idle = false # hideChrome only allowed when using keyboard shortcuts
			branch

		jumpFocusDown: (note, checkDescendants = true) ->
			return followingNote if (followingNote = @findFollowingNote note, checkDescendants)?
		jumpFocusUp: (note) ->
			return previousNote if (previousNote = @findPreviousNote note)?

		tabNote: (note, parent = @findPrecedingInCollection note) ->
			return false unless note.get('rank') > 1
			App.Action.manager.addHistory 'moveBranch', note
			previousParentCollection = @getCollection note.get 'parent_id'
			@removeFromCollection previousParentCollection, note
			Note.eventManager.trigger "expand:#{parent.get('guid')}"
			App.Action.orchestrator.triggerAction 'basicAction', note,
				parent_id: parent.get 'guid'
				rank: parent.descendants.length + 1
				depth: 1 + parent.get 'depth'
			@insertInTree note
		unTabNote: (note, followingNote = false) ->
			return false if note.isARoot(true)
			App.Action.manager.addHistory 'moveBranch', note
			previousParent = @getNote note.get 'parent_id'
			@removeFromCollection previousParent.descendants, note
			@generateNewUnTabAttributes note, followingNote, previousParent
			@insertInTree note
		generateNewUnTabAttributes: (note, followingNote, previousParent) ->
			if followingNote
				note.cloneAttributes followingNote
			else
				App.Action.orchestrator.triggerAction 'basicAction', note,
					parent_id: previousParent.get('parent_id')
					rank: previousParent.get('rank') + 1
					depth: note.get('depth') - 1

		setDropAfter: (dragged, dropAfter) ->
			App.Action.orchestrator.triggerAction 'basicAction', dragged,
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
			preceding = @findPreviousNote note
			return false unless preceding?
			noteHasDescendants = note.hasDescendants()
			return false if preceding.get('depth') < note.get('depth') and noteHasDescendants
			noteToDelete = if noteHasDescendants then [preceding, note] else [note, preceding]
			if note.get('title').length isnt 0 or noteHasDescendants # Backspace on empty note deletes it in most case
				return false if preceding.get('depth') > note.get('depth')
			noteTitle = note.get('title')
			precedingTitle = preceding.get('title')
			@deleteNote noteToDelete[0], false, 'mergeWithPreceding'
			title = precedingTitle + noteTitle
			[noteToDelete[1], title, precedingTitle]
		mergeWithFollowing: (note) ->
			following = @findFollowingNote note
			return false unless following?
			followingHasDescendants = following.hasDescendants()
			return false if following.get('depth') > note.get('depth') and followingHasDescendants
			noteToDelete = if followingHasDescendants then [note, following] else [following, note]
			if following.get('title').length isnt 0 or followingHasDescendants
				return false if following.get('depth') < note.get('depth')
			noteTitle = note.get('title')
			followingTitle = following.get('title')
			@deleteNote noteToDelete[0], false, 'mergeWithPreceding'
			title = noteTitle + followingTitle
			[noteToDelete[1], title, noteTitle]
		mergeDescendants: (mergingBranch, mergedBranch) ->
			t = []
			# Store the descendants in temporary reference array
			# Since the collection,s going to change in @tabNote
			# Can't iterate over it directly
			mergingBranch.descendants.each (descendant) =>
				t.push descendant
			_.each t, (descendant) =>
				descendant.set 'rank', 2
				@tabNote descendant, mergedBranch
		comparator: (note) ->
			note.get 'rank'

)
