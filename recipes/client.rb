
  package 'sensu' do
    action :install
  end
  

  template '/etc/systemd/system/sensu-client.service' do
    source 'sensu-client.service.erb'
    owner 'root'
    group 'root'
    action :create
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
    notifies :restart, 'service[sensu-client]', :delayed
  end

  template '/etc/sensu/client.json' do
    source 'client.json.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end
  
  service 'sensu-client' do
    provider Chef::Provider::Service::Systemd
    retries 5
    retry_delay 10
    action [:enable, :start]
  end