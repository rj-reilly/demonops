#
# Cookbook Name:: demonops
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
chef_gem 'colorize' do #~FC009
  action :install
  compile_time true
end

require 'colorize'

include_recipe 'chef-sugar::default'

query = ''
if node['demonops']['testmode'] then
  query = "hostname:#{node['demonops']['hostname']}"
else
  query = "hostname:#{node['hostname']}"
end


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

log "#{node['hostname']}"

servertypes.each do |servertype|
 puts "found * #{servertype}"
  servers[servertype] = []
  if farm.include? (servertype) then
    puts "found ** #{servertype}"
    farm[servertype].each do |server|
      puts "found *** #{server}".green
      servers[servertype] << server["hostname"]
      if node['demonops']['testmode'] then
        hostname = node['demonops']['hostname']
      else
        hostname = node['hostname']
      end

      if hostname == (server['hostname']) then
        puts "#{servertype}".yellow
        mytypes.push(servertype)
        mytype = mytypes.last
        puts "found **** #{mytype}".green
        me = server
      end
    end
  end
end


if node['demonops']['hostname'] then
  hostsfile_entry node['ipaddress'] do
    hostname  node['demonops']['hostname']
    unique    false
  end
end


############################
#set the id of the dbag
############################
id = farm['id']


mytypes.each do |type|
  case type
  when "servertype_lb"
  puts "Selecting Server Type #{type}".blue

  firewall 'default' do
    action :install
    not_if { ec2? }
  end

  me['ports'].each do |port|
     firewall_rule port do
       port     port.to_i
       command  :allow
       not_if { ec2? }
     end
  end


  package 'haproxy' do
    action :install
  end


  when "servertype_rabbitmq"
  puts "Selecting Server Type #{type}".blue
  include_recipe 'sensu::rabbitmq'


  when "servertype_redis"
  puts "Selecting Server Type #{type}".blue
  #include_recipe 'sensu::redis'

  when "servertype_sensu"
  puts "Selecting Server Type #{type}".blue
  ############################
  #Fire wall rules for everyone
  ############################

  firewall 'default' do
    action :install
    not_if { ec2? }
  end

  me['ports'].each do |port|
     firewall_rule port do
       port     port.to_i
       command  :allow
      not_if { ec2? }
     end
  end

  group 'sensu' do
    action :create
  end

  user 'sensu' do
    comment 'Sensu User'
    uid '1999'
    gid 'sensu'
    shell '/bin/zsh'
  end

  node.default["sensu"]["rabbitmq"]["host"]   = data_bag_item("demonops",id)['servertype_rabbitmq'][0]['hostname']
  node.default["sensu"]["redis"]["host"]      = data_bag_item("demonops",id)['servertype_redis'][0]['hostname']
  node.default["sensu"]["api"]["host"]        = node['hostname']
  node.default["sensu"]["use_embedded_ruby"]  = true

  include_recipe 'sensu::default'
  include_recipe 'sensu::server_service'
  include_recipe 'sensu::api_service'
  include_recipe 'uchiwa::default'


  when "servertype_influxdb"
  puts "Selecting Server Type #{type}".blue

     include_recipe 'influxdb::default'

    directory '/appdata' do
      owner 'influxdb'
      group 'influxdb'
      mode '0755'
      action :create
    end

    influxdb_install 'influxdb' do
      action :install
    end

    cookbook_file '/etc/init.d/influxdb' do
      source 'init.sh'
      owner 'root'
      group 'root'
      mode '0644'
    end

    directory '/var/lib/influxdb' do
      owner 'influxdb'
      group 'influxdb'
      mode '0755'
      action :create
    end

    group 'influxdb' do
      action :create
      gid 888
    end

    user 'influxdb' do
      action :create
      comment 'Influxdb User'
      uid 888
      gid 'users'
      home '/home/influxdb'
      shell '/bin/zsh'
      supports :manage_home => true
    end


  when "servertype_statsd"
  puts "Selecting Server Type #{type}".blue

  when "servertype_grafana"
  puts "Selecting Server Type #{type}".blue

  when "servertype_analysis"
  puts "Selecting Server Type #{type}".blue
  end
end
