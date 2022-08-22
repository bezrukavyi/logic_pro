module LogicPro
  module InteractorForm
    extend ActiveSupport::Concern

    Types = LogicPro::Types

    class_methods do
      def context_form
        @context_form ||= begin
          new_class = Class.new(LogicPro::Form)

          self.const_set('ContextForm', new_class)
        end
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

      def validate(*args, **options)
        context_form.validate(*args, **options)
      end
    end

    def context_form
      @context_form ||= ContextForm.new(context.to_h)
    end
  end
end
