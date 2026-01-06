# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 2)
class AddMissingUniqueIndices < ActiveRecord::Migration[6.0]
  def self.up
    add_index ActsAsTaggableOn.tags_table, :name, unique: true unless index_exists?(ActsAsTaggableOn.tags_table, :name, unique: true)

    if index_exists?(ActsAsTaggableOn.taggings_table, :tag_id)
      # Check if FK exists before trying to remove it
      if foreign_key_exists?(ActsAsTaggableOn.taggings_table, ActsAsTaggableOn.tags_table)
        remove_foreign_key ActsAsTaggableOn.taggings_table, ActsAsTaggableOn.tags_table
      end
      remove_index ActsAsTaggableOn.taggings_table, :tag_id
    end

    remove_index ActsAsTaggableOn.taggings_table, name: 'taggings_taggable_context_idx' if index_exists?(ActsAsTaggableOn.taggings_table, name: 'taggings_taggable_context_idx')
    
    unless index_exists?(ActsAsTaggableOn.taggings_table, name: 'taggings_idx')
      add_index ActsAsTaggableOn.taggings_table,
                %i[tag_id taggable_id taggable_type context tagger_id tagger_type],
                unique: true, name: 'taggings_idx'
    end
              
    add_foreign_key ActsAsTaggableOn.taggings_table, ActsAsTaggableOn.tags_table unless foreign_key_exists?(ActsAsTaggableOn.taggings_table, ActsAsTaggableOn.tags_table)
  end

  def self.down
    remove_foreign_key ActsAsTaggableOn.taggings_table, ActsAsTaggableOn.tags_table
    remove_index ActsAsTaggableOn.tags_table, :name

    remove_index ActsAsTaggableOn.taggings_table, name: 'taggings_idx'

    add_index ActsAsTaggableOn.taggings_table, :tag_id unless index_exists?(ActsAsTaggableOn.taggings_table, :tag_id)
    add_foreign_key ActsAsTaggableOn.taggings_table, ActsAsTaggableOn.tags_table
    
    add_index ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context],
              name: 'taggings_taggable_context_idx'
  end
end
