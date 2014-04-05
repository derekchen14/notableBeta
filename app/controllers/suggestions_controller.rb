class SuggestionsController < ApplicationController
  respond_to :html, :json

  def index
    notebooks = current_user.get_used_trunks
    @suggestions = []
    notebooks.each do |notebook|
      words = $redis.hgetall "Notebook:#{notebook.id}"
      words.each do |word, count|
        @suggestions << {suggestion: word} if count.to_i > 3
      end
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

