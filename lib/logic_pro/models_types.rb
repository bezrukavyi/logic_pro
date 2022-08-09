module LogicPro
  module ModelsTypes
    def self.add(base, classes)
      classes.each do |active_record_class_name|
        active_record_class = active_record_class_name.constantize
        type_class_name = active_record_class.to_s.gsub('Ratesmgr::', '').gsub('::', '_')

        base.const_set(type_class_name, base::Instance(active_record_class).meta(class_name: active_record_class.name).optional)

        collection_constructor = base::Constructor(active_record_class.none.class) do |collection|
          if collection.respond_to?(:model) && collection.model == active_record_class
            collection
          else
            raise "Invalid collection type #{collection.class} for #{active_record_class.name}"
          end
        end

        base.const_set("#{type_class_name}Collection", collection_constructor.meta(class_name: active_record_class.none.class))
      end

      parent
    end
  end
end
