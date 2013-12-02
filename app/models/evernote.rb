#Evernote model directly passes payload data to Evernote, so we can
#just use a tableless model.  This means we can include ActiveModel,
#rather than inheriting from ActiveRecord::Base
class Evernote
	include ActiveModel::Model
	attr_accessor :forest, :trunk, :root, :lastSyncTime, :lastUpdateCount

	fullSyncBefore = getFullSyncBefore # the last time Evernote performed a full sync
	updateCount = getUpdateCount # the server’s updateCount at the last sync

	after_create: fullSync
	after_update: incrementalSync

	def beginSync
		if (lastSyncTime = nil) || (fullSyncBefore > lastSyncTime)
			fullSync
		elsif updateCount = lastUpdateCount #Evernote has no updates
			notes = compileRoots
			sendBranches(notes)
		else
			incrementalSync
		end
	end

	def fullSync
		syncChunk = getSyncChunk(0, 100) # afternUSN = 0, maxEntries = 100
		while chunkHighUSN < updateCount
			addToBuffer(syncChunk)
			getSyncChunk (chunkHighUSN, 100)
		end
		notes = processBuffer
		sendBranches(notes)
	end

	def incrementalSync
		syncChunk = getSyncChunk(lastUpdateCount, 100)
		notes = processBuffer
		sendBranches(notes)
	end

	def sendBranches
		Notes.all.each do |note|
			roots = findRootBranch
			noteData = prepareRootBranch(roots)
			deliverRootBranch(noteData)
		end
		finishSync
	end

	def finishSync
		if usn > lastUpdateCount+1
			incrementalSync
		else
			alert.flash("Your account has been synced")
		end
	end

	# ------------------ SYNC TO RECEIVE CHANGES FROM EVERNOTE ------------------

	def getSyncChunk (afterUSN, maxEntries)
		NoteStore.getSyncChunk(@token_crendentials, afterUSN, maxEntries)
	end

	def addToBuffer (syncChunk)
		@buffer = Array.new
		@buffer.push(syncChunk)
	end

	def processBuffer
		if hasUnprocessableEntities(@buffer)
			alert.flash("Notable cannot process this account.")
		else
			noteList = extractNotes(@buffer)
			notes = mergeNotes(noteList)
			updateMarkers
		end
		notes
	end

	def hasUnprocessableEntities(buffer)
		@buffer.each do |chunkBlock|
			if chunkBlock.note
				return true
			elsif chunkBlock.savedSearch
				return true
			elsif chunkBlock.linkedNotebook
				return true
			else
				return false
		end
	end

	def extractNotes(buffer)
		@buffer.inject([]) do |serverNotes, chunkBlock|
			note = chunkBlock.guid
			serverNotes.push(note)
			if note = "expunged"
				serverNotes[note].pop
			end
			serverNotes
		end
	end

	def mergeNotes(noteList)
		noteList.each do |note|
			unless note.guid in clientNote.guid
				clientNote.guid.push(note.guid)
				if note.name in clientNote.name
					note.name = note.name+ "(2)"
				end
			end
		end
	end

	# ------------------ SEND FRESH BRANCHES TO EVERNOTE -----------------

	def findRootBranch
		branches.each do |branch|
			if branch.fresh
				rootBranch.guid = branch.guid
				while rootBranch.parent_id is not "root"
					rootBranch.guid = branch.parent_id
				end
				rootBranches.push(rootBranch)
			end
		end
		roots # return all the affected rootBranches
	end

	def prepareRootBranch(rootBranches)
		rootBranches.each do |root|
			root_title = root.title
			root_content = Note.compileRoot(root.guid)
			root_note = makeNote ("notestore", "root_title", "root_content")
		end
		noteData # return created note object
	end

	def deliverBranch(noteData)
		if note.USN.empty?
			begin
				note = note_store.createNote(noteData)
			rescue Evernote::EDAM::Error::EDAMUserException => edue
				puts "EDAMUserException: #{edue}"
			rescue Evernote::EDAM::Error::EDAMNotFoundException => ednfe
				puts "EDAMNotFoundException: Invalid parent notebook GUID"
			end
		else
			begin
				note = note_store.updateNote(noteData)
			rescue Evernote::EDAM::Error::EDAMUserException => edue
				puts "EDAMUserException: #{edue}"
			rescue Evernote::EDAM::Error::EDAMNotFoundException => ednfe
				puts "EDAMNotFoundException: Invalid parent notebook GUID"
			end
		end
	end

	private
		def getFullSyncBefore
			NoteStore.getSyncState(@token_crendentials)
		end

		def getUpdateCount
			NoteStore.getUSN(@token_crendentials)
		end

		def updateMarkers
			Evernote.lastUpdateCount = updateCount
			Evernote.lastSyncTime = fullSyncBefore
		end

		def fresh?
			@fresh
		end

		def make_note(note_store, note_title, note_body, parent_notebook=nil)
			n_body = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
			n_body += "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
			n_body += "<en-note>#{note_body}</en-note>"

			our_note = Evernote::EDAM::Type::Note.new
			our_note.title = note_title
			our_note.content = n_body

			## parent_notebook is optional; if omitted, default notebook is used
			# if parent_notebook && parent_notebook.guid
			#   our_note.notebookGuid = parent_notebook.guid
			# end
		end

end

