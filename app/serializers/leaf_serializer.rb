class LeafSerializer < ActiveModel::Serializer
  attributes :id, :attach_src, :filename, :mimetype, :attach_size, :color, :eng, :usn,
  	:emoticon, :note_id
end
