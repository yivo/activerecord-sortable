# encoding: utf-8
# frozen_string_literal: true

module Sortable
  class << self
    def sort(model, new_position)
      traits        = Traits.for(model)
      active_record = traits.active_record
      return nil unless traits.features.sortable?

      new_pos   = new_position.to_s.to_i
      old_pos   = model.position
      arel_attr = active_record.arel_table[:position]
      attr_sql  = "`#{arel_attr.relation.table_name}`.`#{arel_attr.name}`"
      changed   = false

      # 5 => 3
      if new_pos < old_pos
        changed = true
        # 2 => 2
        # 3 => 4
        # 4 => 5
        # 5 => 5

        query = active_record.unscoped.where("#{attr_sql} >= ? and #{attr_sql} < ?", new_pos, old_pos)
        query.update_all("#{attr_sql} = #{attr_sql} + 1")

      # 3 => 5
      elsif old_pos < new_pos
        changed = true
        # 3 => 3
        # 4 => 3
        # 5 => 4

        query = active_record.unscoped.where("#{attr_sql} > ? and #{attr_sql} <= ?", old_pos, new_pos)
        query.update_all("#{attr_sql} = #{attr_sql} - 1")
      end

      if changed && traits.attributes[:updated_at]
        now = active_record.default_timezone == :utc ? Time.now.utc : Time.now
        query.update_all(updated_at: now)
      end

      model.position = new_pos
      model.save!

      nil
    end
  end
end
