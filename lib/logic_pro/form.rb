module LogicPro
  class Form < Dry::Struct
    ATTRIBUTES_PROPERTIES = %i[abstract as].freeze

    Types = LogicPro::Types

    transform_keys(&:to_sym)

    include ActiveModel::Validations

    attr_reader :input

    class << self
      def from_params(params)
        resource_params = params&.permit! || {}
        new(resource_params)
      rescue => error
        failure_parse!(error)
      end

      def from_entity(entity)
        new(build_attribute_entity(entity))
      rescue => error
        failure_parse!(error)
      end

      def attribute(name, type = nil, options = {}, &block)
        @attributes_details ||= {}
        @attributes_details[name] = options.slice(*ATTRIBUTES_PROPERTIES).merge(type: type)

        return super(name, &block) if type.blank?

        super(name, type.meta(omittable: true))

        define_method("#{name}=") do |value|
          input[name.to_sym] = value
        end

        if nested_form?(type)
          define_method("#{name}_form") do
            nested_forms[name.to_sym]
          end
        end

        if nested_array_of_forms?(type)
          define_method("#{name}_forms") do
            nested_forms[name.to_sym]
          end
        end
      end

      def attributes_details
        @attributes_details || {}
      end

      def attribute_entity(name, type, options = {})
        attribute(name, type, options.merge(as: :entity))
        attribute("#{name}_id".to_sym, Types::Coercible::String, abstract: true)
      end

      def attribute_entities(name, type, options = {})
        attribute(name, type, options.merge(as: :entities))
        attribute("#{name}_ids".to_sym, Types::Strict::Array.of(Types::Coercible::Integer), abstract: true)
      end

      def nested_forms
        @nested_forms ||= attributes_details.select do |_key, details|
          nested_form?(details[:type]) || nested_array_of_forms?(details[:type])
        end
      end

      def fields
        @fields ||= attributes_details.reject do |_key, details|
          nested_form?(details[:type]) || nested_array_of_forms?(details[:type])
        end
      end

      def failure_parse!(error)
        entity = new
        entity.errors.add(:base, error.message)

        entity
      end

      private

      def attribute_type_for(name)
        attribute_types[name.to_sym]
      end

      def attribute_types
        attributes_details.map { |name, info| [name, info[:type]] }.to_h
      end

      def nested_form?(type)
        type.respond_to?('<=') && type <= ApplicationForm
      end

      def nested_array_of_forms?(type)
        return false unless type.respond_to?('member')

        type.member.respond_to?('<=') && type.member <= ApplicationForm
      end

      def build_attribute_entity(entity)
        form_params = fetch_entity_attributes(entity)
        form_params.merge!(fetch_nested_entities_attributes(entity))

        form_params[:id] = entity.id

        form_params.symbolize_keys
      end

      def fetch_entity_attributes(entity)
        entity.attributes.symbolize_keys
      end

      def fetch_nested_entities_attributes(entity)
        nested_forms.keys.each_with_object({}) do |nested_entity, result|
          next unless entity.class.reflections.include?(nested_entity.to_s)

          result[nested_entity] = entity.send(nested_entity)&.attributes
        end
      end

      def validates_optional(*keys, **options)
        keys.each do |key|
          validates key.to_sym, options.merge(if: -> { input.key?(key.to_sym) })
        end
      end
    end

    def key?(key)
      input.keys.include?(key)
    end

    def initialize(input = {})
      prepare_input(input)
      @input = input
      super(input)
    end

    def params
      to_h.slice(*input.keys.map(&:to_sym))
    end

    def valid?
      return false if errors.any?

      super()
      assign_nested_forms_errors(errors)
      errors.messages.blank?
    end

    def base_errors
      base = errors[:base]
      base += nested_forms.keys.map { |key| errors[key].present? ? errors[key][:base] : nil }

      base.flatten.compact
    end

    def invalid?
      !valid?
    end

    def failure?
      !valid?
    end

    def success?
      valid?
    end

    def nested_forms
      @nested_forms ||= self.class.nested_forms.map do |key, details|
        [key, build_nested_form_attribute(details[:type], key, input)]
      end.to_h
    end

    def fields
      @fields ||= self.class.fields.map do |name, field_details|
        additional_field_details = field_details.slice(*ATTRIBUTES_PROPERTIES).map do |key, value|
          value = respond_to?(value.to_s) ? send(value) : value

          [key, value]
        end.to_h

        [name, field_details.merge(additional_field_details)]
      end.to_h
    end

    private

    def prepare_input(input)
      return if self.class.attributes_details.blank?

      input.symbolize_keys!

      before_initialize(input)
      prepare_forms(input)
      prepare_entity(input)
      prepare_entities(input)
      after_initialize(input)
    end

    def before_initialize(input)
      # NotImplemented
    end

    def after_initialize(input)
      # NotImplemented
    end

    def prepare_forms(input)
      self.class.nested_forms.each do |key, details|
        next if skip_attribute?(input, key)

        nested_form = build_nested_form_attribute(details[:type], key, input)

        input[key] = nested_form
      end
    end

    def prepare_entity(input)
      self.class.attributes_details.each do |name, attribute|
        next unless attribute[:as] == :entity

        if input["#{name}_id".to_sym].present?
          input[name] = name.to_s.camelize.constantize&.find_by(id: input["#{name}_id".to_sym])
        elsif input[name.to_sym].present?
          input["#{name}_id".to_sym] = input[name.to_sym].id
        end
      end
    end

    def prepare_entities(input)
      self.class.attributes_details.each do |name, attribute|
        next unless attribute[:as] == :entities
        next if input[name.to_sym].present?
        next if skip_attribute?(input, "#{name}_ids")

        collection_class = attribute[:type].type.primitive.to_s.gsub("::ActiveRecord_Relation", "")

        if input["#{name}_ids".to_sym].present?
          input[name] = collection_class.constantize.where(id: input["#{name}_ids".to_sym])
        else
          input[name] = collection_class.constantize.none
        end
      end
    end

    def build_nested_form_attribute(type, key, input)
      if type.respond_to?('member')
        Array(input[key]).compact.map { |data| type.member.new(data) }
      else
        type.new(input[key] || {})
      end
    end

    def assign_nested_forms_errors(errors)
      nested_forms.each do |key, forms|
        forms = Array(forms)

        forms.each_with_index do |form, index|
          next if form.valid?

          error_key = forms.count >= 0 ? "#{key}[#{index}]" : key

          form.errors.each do |error|
            errors.import(error, attribute: "#{error_key}[#{error.attribute}]")
          end
        end
      end
    end

    def skip_attribute?(input, key)
      !input.key?(key.to_sym)
    end
  end
end
