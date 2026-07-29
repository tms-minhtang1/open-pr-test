class Order < ApplicationRecord
  has_many :line_items
  has_many :audit_logs

  def total_cents
    line_items.sum(:amount_cents)
  end

  def self.recalculate_all
    includes(:line_items).find_each do |order|
      # One transaction per order, so a failure rolls back only that order's writes.
      transaction do
        # Sums the eager-loaded rows in Ruby; sum(:amount_cents) sends its own SQL SUM
        # per order even when the association is already loaded.
        order.update!(total_cache_cents: order.line_items.sum(&:amount_cents))
        order.audit_logs.create!(action: "recalculated")
      end
    end
  end

  def total_display
    format("%.2f", BigDecimal(total_cents) / 100)
  end
end
