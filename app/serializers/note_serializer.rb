class NoteSerializer < ActiveModel::Serializer
  attributes :id, :guid, :title, :subtitle, :parent_id, :rank, :depth,
  	:created_at, :collapsed, :fresh, :notebook_id
end
