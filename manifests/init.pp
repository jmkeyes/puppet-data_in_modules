# == Class: data_in_modules

class data_in_modules (
  $parameter,
) {
  notify { "Parameter is ${parameter}.": }
}
