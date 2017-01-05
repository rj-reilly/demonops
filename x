x = {
  'reporting-disabled' => false,
  'meta' => {
    'enabled' => true,
    'dir' => node['influxdb']['meta_file_path'],
    'bind-address' => "#{node['ipaddress']}:8088",
    'retention-autocreate' => true,
    'election-timeout' => '1s',
    'heartbeat-timeout' => '1s',
    'leader-lease-timeout' => '500ms',
    'commit-timeout' => '50ms',
    'cluster-tracing' => false
  },
  'data' => {
    'enabled' => true,
    'dir' => '/appdata/data/influxdb',
    'engine' => 'tsm1',
    # applies only to 0.9.2
    'max-wal-size' => 104_857_600,
    'wal-flush-interval' => '10m0s',
    'wal-partition-flush-delay' => '2s',
    # applies only to >= 0.9.3
    'wal-dir' => node['influxdb']['wal_file_path'],
    'wal-enable-logging' => true,
    'data-logging-enabled' => true
  },
  'hinted-handoff' => {
    'enabled' => true,
    'dir' => node['influxdb']['hinted-handoff_file_path'],
    'max-size' => 1_073_741_824,
    'max-age' => '168h0m0s',
    'retry-rate-limit' => 0,
    'retry-interval' => '1s',
    'retry-max-interval' => '1m0s',
    'purge-interval' => '1h0m0s'
  },
  'cluster' => {
    'write-timeout' => '10s',
    'shard-writer-timeout' => '5s'
  },
  'retention' => {
    'enabled' => true,
    'check-interval' => '30m0s'
  },
  'shard-precreation' => {
    'enabled' => true,
    'check-interval' => '10m0s',
    'advance-period' => '30m0s'
  },
  'monitor' => {
    'store-enabled' => true,
    'store-database' => '_internal',
    'store-interval' => '10s'
  },
  'admin' => {
    'enabled' => true,
    'bind-address' => "#{node['ipaddress']}:8083",
    'https-enabled' => false,
    'https-certificate' => node['influxdb']['ssl_cert_file_path']
  },
  'http' => {
    'enabled' => true,
    'bind-address' => "#{node['ipaddress']}:8086",
    'auth-enabled' => false,
    'log-enabled' => true,
    'write-tracing' => false,
    'pprof-enabled' => false,
    'https-enabled' => false,
    'https-certificate' => node['influxdb']['ssl_cert_file_path']
  },
 'udp' => [
    {
      'enabled' => true,
      'bind-address'=> "#{node['ipaddress']}:8090",
      'database' => 'sys_metrics',
      'batch-size' => 1000,
      'batch-pending' => 5,
      'batch-timeout' => '1s',
      'read-buffer' => 0
    }
  ],
  'continuous_queries' => {
    'log-enabled' => true,
    'enabled' => true,
    'run-interval' => '1s'
  },
  'subscriber' => {
    'enabled' => true
  }
}

