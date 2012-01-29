# This could be way better by using something similar to ActiveRecord::AggregateReflection
if defined?(ActiveRecord::Base)
  module AttrEncrypted
    module Adapters
      module ActiveRecord
        module AttrEncryptedMethod
          def self.extended(base) # :nodoc:
            base.class_eval do
              attr_encrypted_options[:encode] = true
              #class << self; alias_method_chain :method_missing, :attr_encrypted; end
            end
          end

          protected

          # Ensures the attribute methods for db fields have been defined before calling the original 
          # <tt>attr_encrypted</tt> method
          def attr_encrypted(*attrs)
            define_attribute_methods rescue nil
            super

            encrypted_attributes.each do |attr, attr_opts|
              enc_attr = attr_opts[:attribute]
              opts = attr_opts.merge(:mapping => [enc_attr, enc_attr])

              self.reflections = self.reflections.merge(attr => AttrEncryptedReflection.new(:attr_encrypted, attr, opts, self))
            end
            attrs.reject { |attr| attr.is_a?(Hash) }.each { |attr| alias_method "#{attr}_before_type_cast", attr }
          end
        end

        class AttrEncryptedReflection < ::ActiveRecord::Reflection::AggregateReflection
        end

        module QueryMethods
          extend ActiveSupport::Concern

          included do
            alias_method_chain :build_where, :attr_encrypted
            class << self
            end
          end

          # Allows you to use dynamic methods like <tt>find_by_email</tt> or <tt>scoped_by_email</tt> for 
          # encrypted attributes
          #
          # NOTE: This only works when the <tt>:key</tt> option is specified as a string (see the README)
          #
          # This is useful for encrypting fields like email addresses. Your user's email addresses 
          # are encrypted in the database, but you can still look up a user by email for logging in
          #
          def build_where_with_attr_encrypted(opts, other = [])
            ::ActiveRecord::Base.logger.info self
            if opts.is_a? Hash
              opts = opts.dup

              encrypted_attributes.each do |attr, attr_opts|
                opt_key = opts.has_key?(attr) ? attr : (opts.has_key?(attr.to_s) ? attr.to_s : nil)
                if opt_key
                  opts[attr_opts[:attribute]] = ::ActiveRecord::Base.encrypt(attr, opts[opt_key], attr_opts)
                  opts.delete(opt_key)
                end
              end
            end
            build_where_without_attr_encrypted(opts, other)
          end
        end
      end
    end
  end

  ActiveRecord::Base.extend AttrEncrypted::Adapters::ActiveRecord::AttrEncryptedMethod
  ActiveRecord::Relation.send :include, AttrEncrypted::Adapters::ActiveRecord::QueryMethods
end
