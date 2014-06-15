class LeavesController < ApplicationController
  require 'net/http'
  require 'uri'
  respond_to :html, :json

  # GET /leaves.json
  def index
    # @leaves = Leaf.where("user_id = " + params[:user_id])
    # can't do this because leaves has no user_id
    @leaves = Leaf.all
    respond_with(@leaves)
  end

  # GET /leaves/1.json
  def show
    @leaf = Leaf.find(params[:id])
    respond_with @leaf
  end

  # POST /leaves.json
  def create
    @leaf = Leaf.new(params[:leaf])
    respond_with(@leaf) do |format|
      if @leaf.save
        format.html { redirect_to @leaf, notice: 'Leaf was successfully created.' }
        format.json { render json: @leaf, status: :created, location: @leaf }
      else
        format.html { render action: "new" }
        format.json { render json: @leaf.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /leaves/1.json
  def update
    @leaf = Leaf.find(params[:id])
    respond_with(@leaf) do |format|
      if @leaf.update_attributes(params[:leaf])
        format.html { redirect_to @leaf, notice: 'Leaf was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @leaf.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /leaves/1.json
  def destroy
    @leaf = Leaf.find(params[:id])
    @leaf.update_attributes(:trashed => true)
    respond_with(@leaf) do |format|
      format.html { redirect_to leaves_url }
      format.json { head :no_content }
    end
  end

  def attach
    document_res = document_request(params)
    document_body = JSON.parse(document_res.body)
    document_id = document_body["id"]

    session_res = session_request(document_id)
    session_body = JSON.parse(session_res.body)
    sessionID = session_body["id"]

    respond_to do |format|
      format.json { render json: {sessionID: sessionID } }
    end
  end

  def document_request(params)
    uri = URI.parse('https://view-api.box.com/1/documents')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req = Net::HTTP::Post.new(uri.request_uri)
    req["Authorization"] = "Token tjt18xp0gh56wr0xixhbjhooahcc0e4k"
    req["content-type"] = "application/json"
    req.body = '{"url": "'+params[:doc]+'" }'

    return http.request(req)
  end

  def session_request(document_id)
    uri = URI.parse('https://view-api.box.com/1/sessions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req = Net::HTTP::Post.new(uri.request_uri)
    req["Authorization"] = "Token tjt18xp0gh56wr0xixhbjhooahcc0e4k"
    req["content-type"] = "application/json"
    req.body = '{"document_id": "'+document_id+'" }'

    res = http.request(req)
    if res.code == "201"
      return res
    elsif res.code == "202"
      header =  res.header.to_hash
      retry_time = header["retry-after"][0].to_i
      sleep(retry_time)
      session_request(document_id)
    end
  end

end
