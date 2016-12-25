require 'chefspec'
require 'chefspec/berkshelf'
require 'chef-vault/test_fixtures'
require 'json'

at_exit { ChefSpec::Coverage.report! }


def parse_data_bag (path)
  data_bags_path = File.expand_path(File.join(File.dirname(__FILE__), '../test/integration/data_bags'))
  return JSON.parse(File.read("#{data_bags_path}/#{path}"))
end
