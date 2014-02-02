class Notebook < ActiveRecord::Base
  attr_accessible :guid, :title, :modview, :user_id, :eng, :trashed
  has_many :notes, dependent: :destroy
  belongs_to :user

	def self.getTrashed
		Notebook.where("trashed = true")
	end

	def self.deleteByEng (eng)
		notebook = Notebook.where("eng = '#{eng}'").first
		return if notebook.nil?
		notebook.destroy
	end

	# listOfNotebooks => array received from backbone
	# [{0: {name: "[NAME]", eng: "[EVERNOTE_GUID]"}, {1: ...
	def self.createNotebooks (listOfNotebooks, connected_user) 
		listOfNotebooks.each do |key, n| # n => notebook
			if Notebook.where("eng='#{n[:eng]}'").empty?
				fields = {guid: n[:eng], eng: n[:eng], title: n[:name], modview: "outline", user_id: connected_user.id}
				notebook = Notebook.new fields
				notebook.save
			end
		end
	end

end
