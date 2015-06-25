Puppet::Bindings.newbindings('data_in_modules::default') do
  bind {
    name         'data_in_modules'
    to           'function'
    in_multibind 'puppet::module_data'
  }
end
