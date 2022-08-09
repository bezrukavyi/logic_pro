module LogicPro
  module InteractorForm
    extend ActiveSupport::Concern

    module Types
      include LogicPro::Types
    end

    class_methods do
      def context_form
        @context_form ||= Object.const_set('ContextForm', Class.new(LogicPro::Form))
      end

      def attribute(*args)
        context_form.attribute(*args)
      end

      def attribute_entities(*args)
        context_form.attribute_entities(*args)
      end

      def attribute_entity(*args)
        context_form.attribute_entity(*args)
      end

      def validates(*args)
        context_form.validates(*args)
      end

      def validate(*args)
        context_form.validate(*args)
      end
    end

    def context_form
      @context_form ||= self.class.context_form.new(context.to_h)
    end
  end
end
