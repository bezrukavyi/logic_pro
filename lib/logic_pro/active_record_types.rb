module LogicPro
  module ActiveRecordTypes
    def define_types(classes)
      classes.each do |active_record_class_name|
        active_record_class = "::#{active_record_class_name}".constantize
        type_class_name = active_record_class.to_s.gsub('::', '_')

        record_constructor = Constructor(active_record_class) do |entity|
          if entity.blank? || entity.class.name == active_record_class.name
            entity
          else
            raise "Invalid collection type #{collection.class} for #{active_record_class.name}"
          end
        end

        collection_constructor = Constructor(active_record_class.none.class) do |collection|
          if collection.respond_to?(:model) && collection.model.name == active_record_class.name
            collection
          else
            raise "Invalid collection type #{collection.class} for #{active_record_class.name}"
          end
        end

        const_set(type_class_name, record_constructor.meta(class_name: active_record_class.name))

        const_set("#{type_class_name}Collection", collection_constructor.meta(class_name: active_record_class.none.class))
      end
    end
  end
end
