class Leaf < ActiveRecord::Base
  attr_accessible :attachment, :color, :emoticon, :eng, :usn, :note_id
  belongs_to :note

end
