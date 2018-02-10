require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{self.table_name}')"

    results_hash = DB[:conn].execute(sql)
    columns = []
    results_hash.each do |column|
      columns<<column["name"]
    end
    columns.flatten
  end

  def initialize(attributes={})
    attributes.each do |k,v|
      self.send("#{k}=", v)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col|
      values << "'#{send(col)}'" unless send(col).nil?
    end
    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert}
      (#{col_names_for_insert})
      VALUES (#{values_for_insert})
      SQL

    DB[:conn].execute(sql)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    name_hash = {"name"=>name}
    self.find_by(name_hash)
  end

  def self.find_by (lookup = {})
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{lookup.keys.first} = '#{lookup.values.first}'
      SQL

    DB[:conn].execute(sql)
  end

end
