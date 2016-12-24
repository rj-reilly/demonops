#
# Cookbook Name:: demonops
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
chef_gem 'colorize' do
  action :install
  compile_time true
end

require 'colorize'

query = "hostname:#{node['hostname']}"
farm = search('demonops', query) # ~FC003
if farm.count == 0
  farm = data_bag_item('demonops', node['demonops']['farm']).raw_data
else
  farm = farm[0].raw_data
  puts "found farm #{farm}"
end


server = ''
me = ''
servers = {}
mytypes = Array.new
mytype = ''
servertypes = %w(servertype_lb servertype_rabbitmq servertype_redis
                 servertype_sensu servertype_influxdb
                 servertype_statsd servertype_grafana servertype_analysis)



servertypes.each do |servertype|
 puts "found * #{servertype}"
  servers[servertype] = []
  if farm.include? (servertype) then
    puts "found ** #{servertype}"
    farm[servertype].each do |server|
      puts "found *** #{server}".green
      servers[servertype] << server["hostname"]
      if node["hostname"].eql? (server["hostname"]) then
        puts "#{servertype}".yellow
        mytypes.push(servertype)
        mytype = mytypes.last
        puts "found **** #{mytype}".green
        me = server
      end
    end
  end
end

mytypes.each do |type|
  case type
  when "servertype_lb"
  puts "Selecting Server Type #{type}".blue

  when "servertype_rabbitmq"
  puts "Selecting Server Type #{type}".blue

  when "servertype_redis"
  puts "Selecting Server Type #{type}".blue

  when "servertype_sensu"
  puts "Selecting Server Type #{type}".blue
  ############################
  #Fire wall rules for everyone
  ############################

  me['ports'].each do |port|
     firewall_rule "Port#{port}" do
       port     port.to_i
       command  :allow
     end
end

  when "servertype_influxdb"
  puts "Selecting Server Type #{type}".blue

  when "servertype_statsd"
  puts "Selecting Server Type #{type}".blue

  when "servertype_grafana"
  puts "Selecting Server Type #{type}".blue

  when "servertype_analysis"
  puts "Selecting Server Type #{type}".blue
  end
end
