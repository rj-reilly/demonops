name 'demonops'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'all_rights'
description 'Installs/Configures demonops'
long_description 'Installs/Configures demonops'
version '0.1.0'
depends 'firewall'
depends 'sensu'
depends 'uchiwa'
depends 'chef-sugar'
depends 'hostfile'

issues_url 'https://github.com/rj-reilly/demonops/issues' if respond_to?(:issues_url)
source_url 'https://github.com/rj-reilly/demonops' if respond_to?(:source_url)
