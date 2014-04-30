class CreateLeaves < ActiveRecord::Migration
  def change
    create_table :leaves do |t|
      t.string :attach_url
      t.string :filename
      t.string :mimetype
      t.integer :attach_size
      t.string :color
      t.string :emoticon
      t.string :eng
      t.integer :usn
      t.references :note

      t.timestamps
    end
    add_index :leaves, :note_id
  end
end