class Leaf < ActiveRecord::Base
  attr_accessible :attach_url, :filename, :mimetype, :attach_size, :color,
  	:eng, :usn, :emoticon, :note_id
  belongs_to :note

end
