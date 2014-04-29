class CreateLeaves < ActiveRecord::Migration
  def change
    create_table :leaves do |t|
      t.string :attachment
      t.string :color
      t.string :emoticon
      t.string :eng
      t.string :usn
      t.references :note

      t.timestamps
    end
    add_index :leaves, :note_id
  end
end
