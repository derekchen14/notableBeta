class Leaf < ActiveRecord::Base
  attr_accessible :attach_src, :filename, :mimetype, :attach_size, :color,
  	:eng, :usn, :emoticon, :note_id
  belongs_to :note

end
