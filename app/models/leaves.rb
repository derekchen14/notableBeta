class Leaves < ActiveRecord::Base
  belongs_to :note
  attr_accessible :attachment, :color, :emoticon, :eng, :usn
end
