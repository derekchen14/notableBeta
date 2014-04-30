class NotebooksController < ApplicationController
  respond_to :html, :json

  # GET /notebooks.json
  def index
    unless current_user.active_notebook?
      view_context.make_default_notebook
    end
    @notebooks = Notebook.where("user_id = " + params[:user_id] + " AND trashed = false")
    respond_with(@notebooks)
  end

  # GET /notebooks/1.json
  def show
    @notebook = Notebook.find(params[:id])
    respond_with @notebook
  end

  # POST /notebooks.json
  def create
    @notebook = Notebook.new(params[:notebook])
    respond_with(@notebook) do |format|
      if @notebook.save
        format.html { redirect_to @notebook, notice: 'Notebook was successfully created.' }
        format.json { render json: @notebook, status: :created, location: @notebook }
      else
        format.html { render action: "new" }
        format.json { render json: @notebook.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /notebooks/1.json
  def update
    @notebook = Notebook.find(params[:id])
    respond_with(@notebook) do |format|
      if @notebook.update_attributes(params[:notebook])
        format.html { redirect_to @notebook, notice: 'Notebook was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @notebook.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notebooks/1.json
  def destroy
    @notebook = Notebook.find(params[:id])
		# if @notebook.eng?
		# 	@notebook.update_attributes(:trashed => true)
		# else
		# 	@notebook.destroy
		# end
		# @notebook.destroy
    @notebook.update_attributes(:trashed => true)
    respond_with(@notebook) do |format|
      format.html { redirect_to notebooks_url }
      format.json { head :no_content }
    end
  end

  def undoDelete
    @notebook = Notebook.find(params[:id])
    @notebook.update_attributes(:trashed => false)
    respond_with @notebook
  end
  def emptyTrash
    @notebooks = Notebook.where("trashed=true AND user_id=#{params[:user_id]}")
    @notebooks.each do |notebook|
      notebook.destroy
    end
    respond_with(@notebooks) do |format|
      format.html { redirect_to notebooks_url }
      format.json { head :no_content }
    end
  end

end
