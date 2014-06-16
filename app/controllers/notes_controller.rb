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

  def reset
    note = Note.where(guid: params[:guid]).order("id DESC").limit(1).first
    note.destroy # something which might raise an exception
  rescue SystemCallError => error
    puts "--------- System Call Error ----------"
    puts error.message # code that deals with some exception
  rescue ArgumentError => error
    puts "--------- Argument Error ----------"
    puts error.message # code that deals with some other exception
  ensure
    redirect_to root_path # ensure that this code always runs, no matter what
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
      return if newWords == currentWords
      incr = newWords - currentWords
      decr = currentWords - newWords
      puts "incr: #{incr}"
      add_to_library(incr) unless incr.empty?
      remove_from_library(decr) unless decr.empty?
    end

    def add_to_library(words)
      words.each do |word|
        unless prepopulated_words.include?(word)
          $redis.hincrby "Notebook:#{@note.notebook_id}", word, 1
        end
      end
    end

    def remove_from_library(words)
      words.each { |word| $redis.hincrby "Notebook:#{@note.notebook_id}", word, -1 }
    end

    def prepopulated_words
      %w[sophomore achieve apparent calendar congratulate desperate receive ignorance
        judgment conscious February definition]
    end

end

