# frozen_string_literal: true

class WorldFactory
  class BaseWorld
    include ActiveJob::TestHelper

    def self.include_path(path)
      Dir[path].each do |file|
        klass_name = File.basename(file).gsub(/.rb$/, '').split('_').map(&:capitalize).join

        include "World::#{klass_name}".constantize
      end
    end

    def self.plural_factory_names
      @plural_factory_names ||= []
    end

    def self.define(*types, &main_constructor) # rubocop:disable Metrics/MethodLength
      types << @define_group_context.group_name if @define_group_context

      main_type = types.first
      inflected_types = types.map do |type_sym|
        [type_sym, ActiveSupport::Inflector.pluralize(type_sym.to_s).to_sym]
      end
      plural_names = inflected_types.map(&:second)

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
          def #{constructor_name}(opts = #{OPTS})
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
    end

    def self.define_group(group_name)
      @define_group_context = DefineGroupContext.new(self, group_name)
      yield @define_group_context
    ensure
      @define_group_context = nil
    end

    def initialize(options = OPTS)
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
