class NotesController < ApplicationController
  respond_to :html, :json

  def index
    @notes = Note.where("trashed = false AND notebook_id = " + params[:notebook_id])
      .order("depth").order("rank")
    respond_with(@notes)
  end

  def show
    @note = Note.find(params[:id])
    respond_with @note
  end

  def create
    @note = Note.new(params[:note])
    if @note.save
      incr = getWords(@note.title)
      puts "incr: #{incr}"
      add_to_library(incr)
      render json: @note, status: :created, location: @note
    else
      render json: @note.errors, status: :unprocessable_entity
    end
  end

  def update
    @note = Note.find(params[:id])
    currentWords = getWords(@note.title)
    if @note.update_attributes(params[:note])
      newWords = getWords(@note.title)
      getWordDiff(newWords, currentWords)
      head :no_content
    else
      render json: @note.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @note = Note.find(params[:id])
    decr = getWords(@note.title)
    remove_from_library(decr)
		if @note.parent_id == 'root' and @note.eng?
			@note.update_attributes(:trashed => true)
		else
			@note.destroy
		end
    respond_with(@note) do |format|
      format.html { redirect_to notes_url }
      format.json { head :no_content }
    end
  end

  def search
    @notes = Note.where("trashed = false").search(params[:query])
    respond_with(@notes) do |format|
      format.html { @notes }
      # Even though the request from the search form is a JavaScript request
      # we will still send the response as json because that is what Backbone
      # needs to produce the active tree from the search results
      format.js { render json: @notes }
    end
  end

  private
    def getWords(note)
      content = note.gsub(/&nbsp;|\?|\!|\.|,/, ' ')
      newWords = content.gsub(/\s+/, ' ').strip.split(" ")
      newWords.delete_if { |word| word.match /\W/ }
      newWords.delete_if { |word| word.length < 6 }
      return newWords
    end

    def getWordDiff(newWords, currentWords)
      puts "newWords: #{newWords}"
      puts "currentWords: #{currentWords}"
      return if newWords == currentWords
      incr = newWords - currentWords
      decr = currentWords - newWords
      puts "incr: #{incr}"
      add_to_library(incr) unless incr.empty?
      remove_from_library(decr) unless decr.empty?
    end

    def add_to_library(words)
      words.each { |word| $redis.hincrby "Notebook:#{@note.notebook_id}", word, 1 }
    end

    def remove_from_library(words)
      words.each { |word| $redis.hincrby "Notebook:#{@note.notebook_id}", word, -1 }
    end

end

