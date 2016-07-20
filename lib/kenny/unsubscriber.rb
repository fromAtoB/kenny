##
module Kenny
  # Module to unsubscribe all Rails default LogSubscribers from their events.
  module Unsubscriber
    DEFAULT_RAILS_LOG_SUBSCRIBER_CLASSES = [
      ActionView::LogSubscriber,
      ActionController::LogSubscriber,
      ActiveRecord::LogSubscriber,
      ActionMailer::LogSubscriber
    ].freeze

    ##
    # By default, a Rails app instantiates the LogSubscribers listed above and
    # are actively listening to instrumentations listed in:
    # http://edgeguides.rubyonrails.org/active_support_instrumentation.html
    #
    # Unsubscribing is not recommended, unless you want to modify the output
    # to your standard rails logs (development|test|staging|production).log
    #
    # It would be safer to write your chosen instrumentation data to a separate file,
    # setup by the [:logger] configuration (see Readme).

    # In that case, the [:unsubscribe_rails_defaults]
    # field in Kenny's config won't need to be set.
    def self.unsubscribe_from_rails_defaults
      default_rails_log_subscribers.each do |subscriber|
        subscribed_events_for(subscriber).each do |event|
          unsubscribe_listeners_for_event(subscriber, event)
        end
      end
    end

    def self.default_rails_log_subscribers
      ActiveSupport::LogSubscriber.log_subscribers.select do |subscriber|
        DEFAULT_RAILS_LOG_SUBSCRIBER_CLASSES.include? subscriber.class
      end
    end
    private_class_method :default_rails_log_subscribers

    def self.listeners_for(event, subscriber_namespace)
      ActiveSupport::Notifications.notifier.listeners_for(
        "#{event}.#{subscriber_namespace}"
      )
    end
    private_class_method :listeners_for

    def self.unsubscribe_listeners_for_event(subscriber, event)
      subscriber_namespace = subscriber.class.send :namespace
      listeners_for(event, subscriber_namespace).each do |listener|
        if listener.instance_variable_get('@delegate') == subscriber
          ActiveSupport::Notifications.unsubscribe listener
        end
      end
    end
    private_class_method :unsubscribe_listeners_for_event

    def self.subscribed_events_for(subscriber)
      error_msg = "Expected #{subscriber} to be inherited from ActiveSupport::LogSubscriber"
      raise error_msg if subscriber.class.superclass != ActiveSupport::LogSubscriber
      subscriber.public_methods(false).reject { |method| method.to_s == 'call' }
    end
    private_class_method :subscribed_events_for
  end
end