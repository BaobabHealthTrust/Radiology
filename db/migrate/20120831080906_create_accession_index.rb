class CreateAccessionIndex < ActiveRecord::Migration
  def self.up
     add_index :orders, :accession_number
  end

  def self.down
    remove_index :orders, :accession_number
  end
end
