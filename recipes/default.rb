#
# Cookbook Name:: demonops
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
query = "hostname:#{node['hostname']}"
farm = search('demonops', query) # ~FC003
if farm.count == 0
  farm = data_bag_item('demonops', node['demonops']['farm']).raw_data
else
  farm = farm[0].raw_data
  puts "found farm #{farm}"
end
me = ''
servers = {}
mytype = 'fail'
servertypes = %w(servertype_lb servertype_rabbitmq servertype_redis
                 servertype_sensu servertype_influxdb
                 servertype_statsd servertype_grafana servertype_analysis)

servertypes.each do |servertype|
  puts "found * #{servertype}"
  servers[servertype] = []
  if farm.include? (servertype) then
    puts "found ** #{servertype}"
    farm[servertype].each do |server|
      puts "found *** #{server}"
      servers[servertype] << server["hostname"]
      if node["hostname"].eql? (server["hostname"]) then
        mytype = servertype
        puts "found **** #{mytype}"
        me = server
      end
    end
  end
end

servertypes.each do |type|
  case type
  when "servertype_lb"
    puts "found ***** #{type}"

  when "servertype_rabbitmq"
    puts "found ***** #{type}"

  when "servertype_redis"
    puts "found ***** #{type}"

  when "servertype_sensu"
    puts "found ***** #{type}"

  when "servertype_influxdb"
    puts "found ***** #{type}"

  when "servertype_statsd"
    puts "found ***** #{type}"

  when "servertype_grafana"
    puts "found ***** #{type}"

  when "servertype_analysis"
    puts "found ***** #{type}"

  end
end


