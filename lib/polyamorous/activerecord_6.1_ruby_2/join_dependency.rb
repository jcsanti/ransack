require 'polyamorous/activerecord_6.0_ruby_2/join_dependency'

module Polyamorous
  module JoinDependencyExtensions
    def join_constraints(joins_to_add, alias_tracker, references)
      @alias_tracker = alias_tracker
      @joined_tables = {}
      @references = {}

      references.each do |table_name|
        @references[table_name.to_sym] = table_name if table_name.is_a?(String)
      end unless references.empty?

      joins = make_join_constraints(join_root, join_type)

      joins.concat joins_to_add.flat_map { |oj|
        if join_root.match?(oj.join_root) && join_root.table.name == oj.join_root.table.name
          walk(join_root, oj.join_root, oj.join_type)
        else
          make_join_constraints(oj.join_root, oj.join_type)
        end
      }
    end
  end
end
