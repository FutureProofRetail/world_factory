# frozen_string_literal: true

require "active_support/inflector"

class WorldFactory
  module FactoryModule
    def _defines
      @_defines ||= []
    end

    def _define_groups
      @_define_groups ||= []
    end

    def define(*args, **opts, &block)
      _defines << [args, opts, block]
    end

    def define_group(*args, **opts, &block)
      _define_groups << [args, opts, block]
    end

    def included(base)
      _defines.each do |args, options, block|
        base.define(*args, **options, &block)
      end

      _define_groups.each do |args, options, block|
        base.define_group(*args, **options, &block)
      end
    end
  end

  class BaseWorld
    def self.plural_factory_names
      @plural_factory_names ||= []
    end

    def self.define(*types, &main_constructor) # rubocop:disable Metrics/MethodLength
      types << @define_group_context.group_name if @define_group_context

      main_type = types.first
      inflected_types = types.map do |type_sym|
        [type_sym, ActiveSupport::Inflector.pluralize(type_sym.to_s).to_sym]
      end
      plural_names = inflected_types.map { |t| t[1] }

      inflected_types.each do |type_sym, plural|
        plural_factory_names << plural
        attr_reader plural

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{type_sym}
            #{plural}.first
          end
        RUBY

        next unless type_sym == main_type

        constructor_name = "add_#{type_sym}"

        define_method "_#{constructor_name}", &main_constructor
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{constructor_name}(opts = {})
            _#{constructor_name}(opts).tap do |model|
              #{plural_names}.each do |p|
                arr = instance_variable_get('@' + p.to_s)
                arr.push(model) unless arr.include?(model)
              end
            end
          end

          def assure_#{type_sym}(*opts)
            #{plural}.last || #{constructor_name}(*opts)
          end

          def with_#{type_sym}(*opts)
            #{constructor_name}(*opts) && self
          end
        RUBY
      end
    end

    class DefineGroupContext
      attr_reader :group_name

      def initialize(context, group_name)
        @context = context
        @group_name = group_name
      end

      def member(factory_name, &block)
        @context.define(factory_name, @group_name, &block)
      end

      def define(*)
        raise "You cannot call `define` within `define_group :#{group_name}`; instead, use `#member` on the builder block param"
      end
    end

    def self.define_group(group_name, &block)
      @define_group_context = DefineGroupContext.new(self, group_name)

      @define_group_context.instance_exec(@define_group_context, &block)
    ensure
      @define_group_context = nil
    end

    def initialize(options = {})
      self.class.plural_factory_names.uniq.each do |n|
        instance_variable_set("@#{n}", options.fetch(n.to_sym, []))
      end
    end

    def add(type_sym, *args)
      send("add_#{type_sym}", *args)
    end

    def with(type_sym, *args)
      send("with_#{type_sym}", *args)
    end

    def assure(type_sym, *args)
      send("assure_#{type_sym}", *args)
    end
  end
end
