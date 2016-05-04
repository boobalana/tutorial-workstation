#
# Cookbook Name:: tutorial-workstation
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
include_recipe 'chocolatey'
include_recipe 'chrome'

user 'Administrator' do
  password 'P4ssw0rd'
end

chocolatey "git.install" do
  options ({'params' => '"/force /GitAndUnixToolsOnPath"'})
end

%w{poshgit atom}.each do |pack|
  chocolatey pack
end

template 'C:\bookmarks.html' do
  source 'bookmarks.html.erb'
end

chrome 'custom_preferences' do
  params(
    homepage: 'https://10.0.0.12/e/delivery-demo',
    import_bookmarks_from_file: "C:\\\\bookmarks.html"
  )
  action :master_preferences
end

registry_key 'Set Chrome as default HTTP protocol association' do
  action :create
  key 'HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
  values [
    {:name => 'Hash', :type => :string, :data => 'ge1xcShI5CI='},
    {:name => 'ProgId', :type => :string, :data => 'ChromeHTML'},
  ]
end

registry_key 'Set Chrome as default HTTPS protocol association' do
  action :create
  key 'HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice'
  values [
    {:name => 'Hash', :type => :string, :data => 'fjUingCFRtU='},
    {:name => 'ProgId', :type => :string, :data => 'ChromeHTML'},
  ]
end

demo_dir = 'C:\Users\Administrator\delivery-demo'
directory demo_dir
directory File.join(demo_dir, '.chef')
ruby_block 'scp Chef server validation key' do
  block do
    require 'net/ssh'
    require 'net/scp'
    Net::SSH.start('10.0.0.10', 'chef', :password => 'chef', :paranoid => false) do |session|
      session.scp.download! '/home/chef/delivery.pem', File.join(demo_dir, '.chef')
    end
  end
  not_if { File.exist?(File.join(demo_dir, '.chef', 'delivery.pem')) }
end

file File.join(demo_dir, '.chef', 'knife.rb') do
  content <<EOH
node_name            'delivery'
chef_server_url      'https://10.0.0.11/organizations/delivery-demo'
client_key           'C:/Users/Administrator/delivery-demo/.chef/delivery.pem'
cookbook_path        'C:/Users/Administrator/delivery-demo'
trusted_certs_dir    'C:/Users/Administrator/delivery-demo/.chef/trusted_certs'
EOH
end

execute 'Fetch Chef server SSL certificate' do
  command 'knife ssl fetch'
  cwd File.join(demo_dir, '.chef')
  not_if { File.exist?(File.join(demo_dir, '.chef', 'trusted_certs', '10_0_0_11.crt')) }
end

servers = [{:name => 'Chef server', ip: '10.0.0.11'}, {:name => 'Delivery', ip: '10.0.0.12'}]
servers.each do |server|
  powershell_script "Import #{server[:name]} SSL certificate" do
    code <<EOH
      $webRequest = [Net.WebRequest]::Create(\"https://#{server[:ip]}\")
      try { $webRequest.GetResponse() } catch {}
      $cert = $webRequest.ServicePoint.Certificate
      $bytes = $cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)
      Set-Content -value $bytes -encoding byte -path \"$pwd\\#{server[:ip]}.cer\"
      $certpath = \"$pwd\\#{server[:ip]}.cer\"
      $certstore = \"cert:\\\\LocalMachine\\\\Root\"
      Import-Certificate -FilePath $certpath -CertStoreLocation $certstore
      $certstore = \"cert:\\\\LocalMachine\\\\CA\"
      Import-Certificate -FilePath $certpath -CertStoreLocation $certstore
EOH
  end
end
