@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	Given -> @actionManager = new App.Action.Manager()
	Given -> @noteCollection = new App.Note.Collection()
	Given -> @tree = new App.Note.Tree()
	Given -> window.buildTestTree @noteCollection, @tree

	# describe "Action manager should have history length of 0", ->
	# 	Then -> expect(@actionManager._getActionHistory().length).toEqual(0)
	describe "Fake tree & note collection should have populated test data", ->
		Then -> expect(@noteCollection.length).toEqual(14)
		And -> expect(@tree.length).toEqual(5)

	describe "Action manager should", ->
		#adds the "creation" to history
		Given -> @tester1GUID = "e0a5367a-1688-4c3f-98b4-a6fdfe95e779"
		Given -> @tester2GUID = "8a42c5ad-e9cb-43c9-852b-faff683b1b05"
		Given -> @tester3GUID = "7d13cbb1-27d7-446a-bd64-8abf6a441274"
		Given -> @actionManager.addHistory('createNote',{ guid: @tester1GUID })
		Given -> @actionManager.addHistory('createNote',{ guid: @tester2GUID })
		Given -> @actionManager.addHistory('createNote',{ guid: @tester3GUID})

		describe "expect testers to exist", ->
			Then -> expect(=> @tree.findNote(@tester1GUID)).not.toThrow()
			And -> expect(=> @tree.findNote(@tester2GUID)).not.toThrow()
			And -> expect(=> @tree.findNote(@tester3GUID)).not.toThrow()
			And -> expect(@actionManager._getActionHistory().length).toEqual(3)
			And -> expect(@actionManager._getActionHistory()[0]['changes']['guid']).toEqual(@tester1GUID)
			And -> expect(@actionManager._getActionHistory()[1]['changes']['guid']).toEqual(@tester2GUID)
			And -> expect(@actionManager._getActionHistory()[2]['changes']['guid']).toEqual(@tester3GUID)

		describe "undo last items on list, and add to '_redoStack'", ->
			Given -> @actionManager.undo(@tree) #delete Note 3
			Given -> @actionManager.undo(@tree) #delete Note 2
			Given -> @actionManager.undo(@tree) #delete Note 1
			Then -> expect(@actionManager._getUndoneHistory().length).toEqual(3)
			And -> expect(@actionManager._getActionHistory().length).toEqual(0)

			describe "with correct properties.", ->
				Then -> expect(@actionManager._getUndoneHistory()[0]['type']).toEqual('deleteNote')
				And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['guid']).toEqual(jasmine.any(String))
				And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['depth']).toEqual(jasmine.any(Number))
				And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['rank']).toEqual(jasmine.any(Number))
				And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['parent_id']).toEqual(jasmine.any(String))
				And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['title']).toEqual(jasmine.any(String))
				And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['subtitle']).toEqual(jasmine.any(String))
				And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['created_at']).toEqual(jasmine.any(String))
				And -> expect(@actionManager._getUndoneHistory()[0]['changes']['note']['id']).toEqual(jasmine.any(Number))

			describe "give it back to '_undoStack' on 'redo' ", ->
				Given -> @actionManager.redo(@tree) #create Note 1
				Given -> @actionManager.redo(@tree) #create Note 2
				Then -> expect(@actionManager._getActionHistory().length).toEqual(2)
				And -> expect(@actionManager._getUndoneHistory().length).toEqual(1)

				describe "with correct properties.", ->
					Then -> expect(@actionManager._getActionHistory()[1]['type']).toEqual('createNote')
					And -> expect(@actionManager._getActionHistory()[1]['changes']['guid']).toEqual(jasmine.any(String))

		# end checking redo and undo stacks
		# start checking for the existance 

		describe "undo last item on the list and remove from collection", ->
			Given -> @actionManager.undo(@tree) #delete note 3
			Given -> @actionManager.undo(@tree) #delete note 2
			Then -> expect(=> @tree.findNote(@tester1GUID)).not.toThrow("#{@tester1GUID} not found")
			And -> expect(=> @tree.findNote(@tester2GUID)).toThrow("#{@tester2GUID} not found. Aborting")
			And -> expect(=> @tree.findNote(@tester3GUID)).toThrow("#{@tester3GUID} not found. Aborting")

			describe "then return the item to collection on 'redo' ", ->
				Given -> @actionManager.redo(@tree)
				Given -> @actionManager.redo(@tree)
				Then -> expect(=> @tree.findNote(@tester1GUID)).not.toThrow()
				And -> expect(=> @tree.findNote(@tester2GUID)).not.toThrow()
				And -> expect(=> @tree.findNote(@tester3GUID)).not.toThrow()

)