class QueryController < ApplicationController
  after_action :reset_database, except: [ :index, :examples ]

  def index
    @queries = Queries
  end

  def examples
    @queries = Queries.map do |q|
      params[q[:input][:name]] = q[:input][:example]

      result = q.dup

      begin
        value = eval(q[:query])
        result[:result] = case value
                           when TrueClass, FalseClass, Numeric, String
                             value
                           else
                             Array(value)
                           end.inspect
      rescue => e
        result[:result] = e
      end

      params[q[:input][:name]] = nil
      result[:sql] = last_sql

      reset_database

      result
    end

    render layout: "examples"
  end

  Queries.each do |query|
    class_eval <<-RUBY
      def #{query[:action]}
        begin
          value = #{query[:query]}
          result = case value
                   when TrueClass, FalseClass, Numeric, String
                     value
                   else
                     Array(value)
                   end.inspect

          show result
        rescue => e
          @error = e
          @sql = last_sql
          render partial: "error"
        end
      end
    RUBY
  end

  private

  def show query
    @sql = last_sql
    render partial: "result", locals: { query: query }
  end

  def last_sql
    sql = $last_sql
    $last_sql = nil
    sql
  end

  # Only Product (plus its cache rows) is reseeded between examples: the
  # whole point of this page is to let a cache-poisoning example's result
  # include the solid_cache_entries rows it just wrote, so those are left
  # alone until the *next* example runs.
  def reset_database
    Product.delete_all
    SolidCache::Entry.delete_all
    load File.join(Rails.root, "db/seeds.rb")
  rescue ActiveRecord::StatementInvalid
    nil # cache table not migrated in this environment; nothing to reset
  end
end
