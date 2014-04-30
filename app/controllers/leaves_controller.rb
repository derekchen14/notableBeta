class LeavesController < ApplicationController
  respond_to :html, :json

  # GET /leaves.json
  def index
    # unless current_user.active_leaf?
    #   view_context.make_default_leaf
    # end
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

end
