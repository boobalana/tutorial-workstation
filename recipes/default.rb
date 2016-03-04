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
