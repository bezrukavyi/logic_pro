module LogicPro
  class Interactor
    include ::Interactor
    include LogicPro::InteractorForm

    def to_proc
      public_method(:call).to_proc
    end

    def run!
      with_hooks do
        context.called!(self)
        call
      end
    rescue StandardError => e
      context.rollback!
      fail_error!(e)
    end

    private

    def validate_attributes!
      validate_form!(context_form)
    end

    def validate_form!(form)
      return if form.valid?

      form.errors.add(:base, 'Invalid data') if form.errors[:base].blank?
      context.fail!(errors: form.errors)
    end

    def transaction(transaction_class = ActiveRecord::Base, &block)
      transaction_class.transaction(&block)
    rescue StandardError => e
      fail_error!(e)
    end

    def rescue_errors
      yield
    rescue StandardError => e
      Rails.logger.error(e.message)
    end

    def fail_error!(error)
      context.fail! if error.is_a?(Interactor::Failure)

      error_message = error.is_a?(String) ? error : error.message
      context.fail!(errors: errors_object(error_message))
    end

    def errors_object(messages)
      errors = ActiveModel::Errors.new(self)

      Array(messages).each do |message|
        errors.add(:base, message)
      end

      errors
    end
  end
end
