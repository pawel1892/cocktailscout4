class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reportable, polymorphic: true, null: false
      t.integer :reason, null: false, default: 0
      t.text :description
      t.integer :status, null: false, default: 0
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }
      t.text :resolution_notes
      t.integer :old_id

      t.timestamps
    end

    add_index :reports, :status
  end
end
