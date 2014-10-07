require 'spec_helper_acceptance'
# These tests are designed to ensure that the module, when ran with defaults,
# sets up everything correctly and allows us to connect to stash.
describe 'stash', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  it 'with defaults' do
    pp = <<-EOS
      $jh = $osfamily ? {
        'RedHat'  => '/usr/lib/jvm/java-1.7.0-openjdk.x86_64',
        'Debian'  => '/usr/lib/jvm/java-7-openjdk-amd64',
        default   => '/opt/java',
      }
      if versioncmp($::puppetversion,'3.6.1') >= 0 {
        $allow_virtual_packages = hiera('allow_virtual_packages',false)
        Package {
          allow_virtual => $allow_virtual_packages,
        }
      }
      class { 'postgresql::globals':
        manage_package_repo => true,
        version             => '9.3',
      }->
      class { 'postgresql::server': } ->
      class { 'java':
        distribution => 'jdk',
      } ->
      class { 'stash':
        downloadURL => 'http://10.0.0.17:81/',
        javahome    => $jh,
      }
      class { 'stash::gc': }
      class { 'stash::facts': }
      postgresql::server::db { 'stash':
        user     => 'stash',
        password => postgresql_password('stash', 'password'),
      }
    EOS
    apply_manifest(pp, :catch_failures => true)
    shell 'curl --connect-timeout 1 --retry 240 localhost:7990', :acceptable_exit_codes => [0,7]
    sleep 120
    shell 'curl --connect-timeout 1 --retry 240 localhost:7990', :acceptable_exit_codes => [0,7]
    apply_manifest(pp, :catch_changes => true)
  end

  describe port(7990) do
    it { is_expected.to be_listening }
  end

end

#    curl_with_retries(desc, host, url, desired_exit_codes, max_retries = 60, retry_interval = 1) 
#M#  describe process("java") do
#M#    it { should be_running }
#M#  end
#M#
#M#  describe port(7990) do
#M#    it { is_expected.to be_listening }
#M#  end
#M#
#M#  describe package('git') do
#M#    it { should be_installed }
#M#  end
#M#
#M#  describe service('stash') do
#M#    it { should be_enabled }
#M#  end
#M#
#M#  describe user('stash') do
#M#    it { should exist }
#M#  end
#M#
#M#  describe user('stash') do
#M#    it { should belong_to_group 'stash' }
#M#  end
#M#
#M#  describe user('stash') do
#M#    it { should have_login_shell '/bin/bash' }
#M#  end
#M#
#  describe file('/etc/httpd/conf/httpd.conf') do
#    its(:content) { should match /ServerName www.example.jp/ }
#  end
#
#  describe file('/var/log/httpd') do
#    it { should be_directory }
#  end
#
#describe yumrepo('epel'), :if => os[:family] == 'redhat'  do
#  it { should exist }
#end
#  it 'can connect with psql' do
#    psql('--command="\l" postgres', 'postgres') do |r|
#      expect(r.stdout).to match(/List of databases/)
#    end
#  end
