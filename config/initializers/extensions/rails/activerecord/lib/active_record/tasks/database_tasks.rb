require 'active_record/tasks/database_tasks'

module ActiveRecord
  module Tasks
    module DatabaseTasks

      def migrate
        verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        scope   = ENV['SCOPE']

        migrations_paths.each do |migration_path|
          verbose_was, Migration.verbose = Migration.verbose, verbose
          namespace = File.basename migration_path
          db_configs = Base.configurations
          Base.establish_connection db_configs[namespace][Rails.env] unless namespace === "migrate"
          begin
            Migrator.migrate(migration_path, version) do |migration|
              scope.blank? || scope == migration.scope
            end
          ensure
            Migration.verbose = verbose_was
          end
        end
      end

      def migrations_paths
        paths = Rails.application.paths['db/migrate'].to_a
        root_path = paths.first

        namespaces = ENV['MIGRATION_NAMESPACE'] ||
        ENV['MIGRATION_NAMESPACES'] ?
          (ENV['MIGRATION_NAMESPACE'] ||
          ENV['MIGRATION_NAMESPACES']).split(",").flatten :
        []

        namespaces.each do |namespace|
          paths << "#{root_path}/#{namespace.strip}"
        end

        @migrations_paths ||= paths
      end

      def create(*arguments)
        configuration = arguments.first
        begin
          class_for_adapter(configuration['adapter']).new(*arguments).create
        rescue DatabaseAlreadyExists
          $stderr.puts "#{configuration['database']} already exists"
        rescue Exception => error
          $stderr.puts error, *(error.backtrace)
          $stderr.puts "Couldn't create database for #{configuration.inspect}"
        else
          $stderr.puts "Database #{configuration['database']} has been created"
        end
      end

      private

      def each_current_configuration(environment)
        environments = [environment]
        # add test environment only if no RAILS_ENV was specified.
        environments << 'test' if environment == 'development' &&
          ENV['RAILS_ENV'].nil?

        configurations = []

        db_configs = Base.configurations
        namespaces = ENV['MIGRATION_NAMESPACE'] ||
        ENV['MIGRATION_NAMESPACES'] ?
          (ENV['MIGRATION_NAMESPACE'] ||
          ENV['MIGRATION_NAMESPACES']).split(",").flatten :
        []

        namespaces_configs = db_configs.values_at(*namespaces)
        if namespaces_configs.any?
          namespaces_configs.each do |namespace|
            configurations << namespace.values_at(*environments)
          end
        end

        configurations << db_configs.values_at(*environments)
        configurations.flatten.compact.each do |configuration|
          yield configuration unless configuration['database'].blank?
        end
      end

    end
  end
end
