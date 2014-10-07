#require 'minitest'
#require 'minitest/autorun'
#require 'beaker-rspec'
#require 'pry'
require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'

hosts.each do |host|
  on host, 'echo "Acquire::http::proxy \"http://10.0.0.17:3128\";" >> /etc/apt/apt.conf; exit 0'
  on host, 'echo "Acquire::https::proxy \"http://10.0.0.17:3128\";" >> /etc/apt/apt.conf; exit 0'
  on host, 'echo "proxy=http://10.0.0.17:3128" >> /etc/yum.conf; exit 0'
  on host, 'rm -f /etc/yum/pluginconf.d/fastestmirror.conf; exit 0'
  on host, "sed -i 's/^mirrorlist=/#mirrorlist=/g'  /etc/yum.repos.d/*; exit 0"
  on host, "sed -i 's/#baseurl=/baseurl=/g' /etc/yum.repos.d/*; exit 0"
  install_puppet
  on host, "mkdir -p #{host['distmoduledir']}"
end

UNSUPPORTED_PLATFORMS = ['AIX','windows','Solaris']

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module
    puppet_module_install(
      :source => proj_root,
      :module_name => 'stash',
      :ignore_list => [ 'spec/fixtures/*', '.git/*', '.vagrant/*' ],
    )
    hosts.each do |host|
      on host, "/bin/touch #{default['puppetpath']}/hiera.yaml"
      on host, 'chmod 755 /root'
      if fact('osfamily') == 'Debian'
        on host, "echo \"en_US ISO-8859-1\nen_NG.UTF-8 UTF-8\nen_US.UTF-8 UTF-8\n\" > /etc/locale.gen"
        on host, '/usr/sbin/locale-gen'
        on host, '/usr/sbin/update-locale'
      end
      on host, puppet('module','install','puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-postgresql'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','yguenane-repoforge'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','mkrakowitzer-deploy'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-java'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
