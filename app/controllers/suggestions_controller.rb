class WordsController < ApplicationController
  respond_to :html, :json

  def index
    notebooks = User.get_used_trunks
    @suggestions = []
    notebooks.each do |notebook|
      words = $redis.hgetall "Notebook:#{notebook.id}"
      words.each { |word, count| @suggestions << word if count.to_i > 3 }
    end
    respond_with @suggestions # send to bloodhound
  end

  def show
    words = $redis.hget "Notebook:#{notebook.id}", params[:word]
    respond_with words
  end

  def update
    $redis.hincrby "Notebook:#{notebook.id}", word, 1
  end

  def destroy
    $redis.hdel "Notebook:#{notebook.id}", word
  end

end

