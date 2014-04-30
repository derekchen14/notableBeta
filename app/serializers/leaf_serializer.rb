class LeafSerializer < ActiveModel::Serializer
  attributes :attach_url, :filename, :mimetype, :attach_size, :color, :eng, :usn,
  	:emoticon, :note_id
end
