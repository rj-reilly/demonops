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


  when "servertype_rabbitmq"
  puts "Selecting Server Type #{type}".blue
  #include_recipe 'sensu::rabbitmq'


  when "servertype_redis"
  puts "Selecting Server Type #{type}".blue
  #include_recipe 'sensu::redis'

  package 'redis-server' do
    action :install
  end
  

  package 'redis-tools' do
    action :install
  end
  

  when "servertype_sensu"
  puts "Selecting Server Type #{type}".blue
  ############################
  #Fire wall rules for everyone
  ############################


  group 'sensu' do
    action :create
  end

  user 'sensu' do
    comment 'Sensu User'
    uid '1999'
    gid 'sensu'
    shell '/bin/zsh'
  end
  
  cookbook_file '/etc/sensu/conf.d/transport.json' do
    source 'transport.json'
    owner 'sensu'
    group 'sensu'
    mode '0644'
  end
  

  cookbook_file '/etc/sensu/conf.d/api.json' do
    source 'api.json'
    owner 'sensu'
    group 'sensu'
    mode '0644'
  end
  
  execute 'import key' do
    command 'wget -q https://sensu.global.ssl.fastly.net/apt/pubkey.gpg -O- | sudo apt-key add -'
    action :run
  end

  apt_repository 'sensu' do
    uri 'https://sensu.global.ssl.fastly.net/apt'
    components ['main']  
  end

  
  apt_update

  package 'sensu' do
    action :install
  end
  
  when "servertype_influxdb"
  puts "Selecting Server Type #{type}".blue

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
      manage_home true
    end
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
      source 'influxdb'
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




  when "servertype_statsd"
  puts "Selecting Server Type #{type}".blue

  when "servertype_grafana"
  puts "Selecting Server Type #{type}".blue

  when "servertype_analysis"
  puts "Selecting Server Type #{type}".blue
  end
end
