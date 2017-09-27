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

package 'zsh' do
  action :install
end


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

  package %w(redis-server redis-tools) do
    action :install
  end

  package %w(npm nodejs) do
    action :install
  end
  

  when "servertype_sensu"
  puts "Selecting Server Type #{type}".blue

  group 'sensu' do
    action :create
  end

  user 'sensu' do
    comment 'Sensu User'
    uid '1999'
    gid 'sensu'
    shell '/bin/zsh'
  end
    
  directory '/etc/sensu/conf.d/' do
    owner 'sensu'
    group 'sensu'
    mode '0755'
    action :create
    recursive true
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
  
   cookbook_file '/etc/sensu/conf.d/config.json' do
    source 'config.json'
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

  
  template '/etc/systemd/system/sensu-server.service' do
    source 'sensu-server.service.erb'
    owner 'root'
    group 'root'
    action :create
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
    notifies :restart, 'service[sensu-server]', :delayed
  end

  template '/etc/systemd/system/sensu-api.service' do
    source 'sensu-api.service.erb'
    owner 'root'
    group 'root'
    action :create
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
    notifies :restart, 'service[sensu-api]', :delayed
  end



  # cookbook_file '/etc/sensu/extensions/influxdb_line_protocol.rb' do
  #   source 'influxdb_line_protocol.rb'
  #   owner 'sensu'
  #   group 'sensu'
  #   mode '0644'
  #   notifies :restart, 'service[sensu-server]', :delayed
  #   notifies :restart, 'service[sensu-api]', :delayed
  # end

  cookbook_file '/etc/sensu/conf.d/handlers.json' do
    source 'handlers.json'
    owner 'sensu'
    group 'sensu'
    mode '0644'
    notifies :restart, 'service[sensu-server]', :delayed
    notifies :restart, 'service[sensu-api]', :delayed
  end

  plugins = data_bag_item('demonops', id)['plugins']

  plugins.each do |p|
    sensu_gem "sensu-plugins-#{p}" do
    end  
  end

  # gem_package 'influxdb' do
  #   gem_binary '/opt/sensu/embedded/bin/gem'
  # end

  # cookbook_file '/etc/sensu/plugins/influxdb_line_protocol.rb' do
  #   source 'influxdb_line_protocol.rb'
  #   owner 'sensu'
  #   group 'sensu'
  #   mode '0755'
  #   notifies :restart, 'service[sensu-server]', :immediately
  #   notifies :restart, 'service[sensu-api]', :immediately
  # end
  
  # cookbook_file '/etc/sensu/conf.d/mutators.json' do
  #   source 'mutators.json'
  #   owner 'sensu'
  #   group 'sensu'
  #   mode '0644'
  #   notifies :restart, 'service[sensu-server]', :immediately
  #   notifies :restart, 'service[sensu-api]', :immediately
  # end
  
  sensu_gem "influxdb"

  cookbook_file "/etc/sensu/extensions/influx.rb" do
    source "influx.rb"
    mode 0755
  end

  sensu_snippet "influx" do
    content(
      :host => '127.0.0.1',
      :port => '8086',
      :user => 'root',
      :password => 'root',
      :database => 'statsd',
      :strip_metric => node.name
    )
  end
   
  cookbook_file '/etc/sensu/conf.d/checks.json' do
    source 'checks.json'
    owner 'sensu'
    group 'sensu'
    mode '0644'
    notifies :restart, 'service[sensu-server]', :delayed
    notifies :restart, 'service[sensu-api]', :delayed
  end


  link '/etc/sensu/extensions/mutator-influxdb-line-protocol.rb' do
    to '/opt/sensu/embedded/bin/mutator-influxdb-line-protocol.rb'
    notifies :restart, 'service[sensu-server]', :delayed
    notifies :restart, 'service[sensu-api]', :delayed
  end

  execute 'systemctl daemon-reload' do
    command 'systemctl daemon-reload'
    action :nothing
  end

  service 'sensu-server' do
    provider Chef::Provider::Service::Systemd
    retries 5
    retry_delay 10
    action [:enable, :start]
  end
  

  service 'sensu-api' do
    provider Chef::Provider::Service::Systemd
    retries 5
    retry_delay 10
    action [:enable, :start]
  end
  
  
  package 'uchiwa' do
    action :install
  end
  
template '/etc/sensu/uchiwa.json' do
  source 'uchiwa.json.erb'
  owner 'sensu'
  group 'sensu'
  mode '0644'
  notifies :restart, 'service[uchiwa]'
end

  service 'uchiwa' do
    supports :status => true, :restart => true, :reload => true
    action [:start, :enable]
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
    
  influxdb_database 'statsd' do
    action :create
  end


  when "servertype_statsd"
  puts "Selecting Server Type #{type}".blue

  when "servertype_grafana"
  puts "Selecting Server Type #{type}".blue

  execute 'import key' do
    command 'curl -L https://packagecloud.io/grafana/stable/gpgkey | sudo apt-key add -'
    action :run
    notifies :create, 'file[/tmp/apt-key]', :immediately
  end
  
  file '/tmp/apt-key' do
    action :nothing
    owner 'root'
    group 'root'
    mode '0644'
  end
  
  apt_repository 'grafana' do
    uri 'deb https://packagecloud.io/grafana/stable/debian/'
    components ['main']
    distribution 'jessie'
    keyserver 'packagecloud.io'
    action :add
    deb_src true
    ignore_failure true
    end

    package 'grafana' do
      action :install
    end

    service 'grafana-server' do
      supports :status => true, :restart => true, :reload => true
      action [:start, :enable]
    end
    
    

  when "servertype_analysis"
  puts "Selecting Server Type #{type}".blue
  end

end
