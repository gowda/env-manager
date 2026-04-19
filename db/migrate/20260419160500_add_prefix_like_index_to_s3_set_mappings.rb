class AddPrefixLikeIndexToS3SetMappings < ActiveRecord::Migration[8.1]
  def change
    add_index :s3_set_mappings,
      :key_pattern,
      name: "index_s3_set_mappings_prefix_like",
      opclass: :text_pattern_ops,
      where: "match_kind = 'prefix'"
  end
end
