# Enable service during startup and start service
node.default['vsftpd']['enabled'] = true

# Configuration directory of vsftpd
node.default['vsftpd']['etcdir'] = '/etc/vsftpd'

ftpUsername = 'ftpUser'
hashedPasword = `openssl passwd -1 "yourspecialpassword"`
groupId = 2016
groupName = ftpUsername

# Home necomplus user directory
node.default['vsftpd']['ftpUserRootDir'] = "/home/#{ftpUsername}"

# This is different on some distributions
node.default['vsftpd']['configfile'] = value_for_platform_family(
    'rhel'   => '/etc/vsftpd/vsftpd.conf',
    'debian' => '/etc/vsftpd.conf',
    'default' => '/etc/vsftpd.conf'
)

# Depending on configuration of vsftpd allow users to run
# non-chroot or defines users that have to be chroot'ed
# Default: chroot all users but those defined here
node.default['vsftpd']['chroot'] = [ ]

# Various configuration options with some sane defaults
# For details on these please check the official documentation
node.default['vsftpd']['config'] = {
    'local_enable'                => 'YES',
    'write_enable'                => 'YES',
    'xferlog_enable'              => 'YES',
    'connect_from_port_20'        => 'YES',
    'chroot_local_user'           => 'YES',
    'listen'                      => 'YES',
    'pasv_enable'                 => 'YES',
    'pasv_address'                => (node['cloud'] && node['cloud']['public_ipv4']) || node['ipaddress'],
    'pasv_max_port'               => '13100',
    'pasv_min_port'               => '13000',
    'port_enable'                 => 'YES',
    'pam_service_name'            => 'vsftpd',
    'dirmessage_enable'           => 'YES',
    'use_localtime'               => 'YES',
    'secure_chroot_dir'           => '/var/run/vsftpd/empty',
    'rsa_cert_file'               => '/etc/ssl/private/vsftpd.pem',
    'passwd_chroot_enable'        => 'YES'
}

# create ftp user group
group groupName  do
  action :create
  gid groupId
end

# create FTP user
user ftpUsername do
  action :create
  comment "The #{ftpUsername} user"
  gid groupId
  home "/home/./#{ftpUsername}"
  shell '/bin/bash'
  password hashedPasword
end

directory node['vsftpd']['etcdir'] do
  action :create
  user 'root'
  group 'root'
  mode '755'
end

# create FTP user folder
directory node['vsftpd']['ftpUserRootDir'] do
  action :create
  user ftpUsername
  group groupName
  mode '755'
end

{ 'vsftpd.conf.erb' => node['vsftpd']['configfile']
}.each do |template, destination|
  template destination do
    source template
    notifies :restart, 'service[vsftpd]', :delayed
  end
end

include_recipe 'lcrasovan::vsftpd_define_service'