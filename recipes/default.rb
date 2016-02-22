#
# Cookbook Name:: tutorial-workstation
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
include_recipe 'chocolatey'
include_recipe 'chrome'

user 'chef' do
  comment 'Chef Demo User'
  password "P4ssw0rd"
end

group 'Administrators' do
  members "chef"
  append true
  action :modify
end

chocolatey "git.install" do
  options ({'params' => "'/force'"})
end

%w{poshgit atom}.each do |pack|
  chocolatey pack
end

template 'C:\bookmarks.html' do
  source 'bookmarks.html.erb'
end

chrome 'custom_preferences' do
  params(
    homepage: 'http://chef.io/',
    import_bookmarks_from_file: "C:\\\\bookmarks.html"
  )
  action :master_preferences
end
