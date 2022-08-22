module LogicPro
  module PrimitiveTypes
    include Dry.Types()

    Boolean = Bool.constructor { |value| ActiveRecord::Type::Boolean.new.serialize(value) }
    String = Constructor(::String, &:to_s)
    Symbol = Constructor(::String, &:to_sym)
    Hash = Constructor(::Hash, &:to_h)
    Float = Constructor(::Float, &:to_f)
    Integer = Constructor(::Integer, &:to_i)
    DateTime = Constructor(::DateTime) { |value| ::DateTime.parse(value.to_s) if value.present? }
    InteractorType = Constructor(::Interactor) { |value| value }
  end
end
