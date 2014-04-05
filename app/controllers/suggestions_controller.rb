class SuggestionsController < ApplicationController
  respond_to :html, :json

  def index
    notebooks = current_user.get_used_trunks
    @suggestions = []
    notebooks.each do |notebook|
      words = $redis.hgetall "Notebook:#{notebook.id}"
      words.each do |word, count|
        $redis.hdel "Notebook:#{notebook.id}", word if count.to_i <= 0
        @suggestions << {suggestion: word} if count.to_i > 3
      end
    end
    respond_with @suggestions # send to bloodhound
  end

  def show
    suggest = []
    words = $redis.hgetall "Notebook:#{params[:id]}"
    words.each do |word, count|
      if word.start_with? params[:q] and count.to_i > 3
        suggest << {suggestion: word}
      end
    end
    respond_with suggest
  end

  def update
    $redis.hincrby "Notebook:#{notebook.id}", word, 1
  end

  def destroy
    $redis.hdel "Notebook:#{notebook.id}", word
  end

end

