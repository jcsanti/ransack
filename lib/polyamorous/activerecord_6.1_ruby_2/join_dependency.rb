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

    private
      def make_constraints(parent, child, join_type)
        foreign_table = parent.table
        foreign_klass = parent.base_klass

        join_type = child.join_type || join_type if join_type == Arel::Nodes::InnerJoin

        child.join_constraints(foreign_table, foreign_klass, join_type, alias_tracker) do |reflection|
          table, terminated = @joined_tables[reflection]
          root = reflection == child.reflection

          if table && (!root || !terminated)
            @joined_tables[reflection] = [table, root] if root
            next table, true
          end

          table_name = @references[reflection.name.to_sym]

          table = alias_tracker.aliased_table_for(reflection.klass.arel_table, table_name) do
            name = reflection.alias_candidate(parent.table_name)
            root ? name : "#{name}_join"
          end

          @joined_tables[reflection] ||= [table, root] if join_type == Arel::Nodes::OuterJoin
          table
        end.concat child.children.flat_map { |c| make_constraints(child, c, join_type) }
      end
  end
end
