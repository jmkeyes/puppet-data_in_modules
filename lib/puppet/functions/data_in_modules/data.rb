Puppet::Functions.create_function(:'data_in_modules::data') do
  def data()
    @data ||= module_data
  end

  private
  def module_path
    environment = closure_scope.compiler.environment.to_s
    @module_path ||= Puppet::Module.find('data_in_modules', environment).path
  end

  def module_data_path
    @module_data_path ||= File.join(module_path, 'data')
  end

  def module_data_config
    return @module_data_config unless @module_data_config.nil?

    default_config = {
      :backends  => [ 'yaml' ],
      :hierarchy => [ 'common' ],
    }

    config_path = File.join(module_data_path, 'config.yaml')

    local_config = YAML.load_file(config_path) rescue {}

    @module_data_config ||= default_config.merge(local_config)
  end

  def module_data_backends
    @module_data_backends ||= {
      'yaml' => proc { |io| YAML.load(io) rescue {} },
      'json' => proc { |io| JSON.parse(io) rescue {} },
    }
  end

  def module_data
    scope       = closure_scope.dup
    backends    = module_data_config[:backends]
    hierarchy   = module_data_config[:hierarchy]

    filter      = proc { |i| i.nil? or i.empty? }
    interpolate = proc { |c| c.gsub(/%\{([^\}]+)\}/) { scope[$1] } }

    categories = hierarchy.map(&interpolate).reject(&filter)

    to_files = proc { |category| File.join(module_data_path, category) }

    as_data = proc do |category|
      process_backend_data = proc { |name, path|
        next {} unless File.exist?(path)
        backend = module_data_backends[name]
        data = File.read(path)
        backend.call(data)
      }

      backends.reduce({}) do |output, name|
        path = "%s.%s" % [ category, name ]
        data = process_backend_data[name, path]
        output.deep_merge(data)
      end
    end

    categories.map(&to_files).collect(&as_data).reduce(&:deep_merge)
  end
end
