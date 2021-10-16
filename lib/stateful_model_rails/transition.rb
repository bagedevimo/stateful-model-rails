# frozen_string_literal: true

class StatefulModelRails::Transition
  attr_reader :from, :to

  def initialize(from, to)
    @from = from
    @to = to
  end

  def ==(other)
    from == other.from && to == other.to
  end
end
