group 'web_admin'

user 'web_admin' do
  group 'web_admin'
  system true
  shell '/bin/bash'
end

template '/var/www/html/index.html' do # ~FC033
  source 'index.html.erb'
  mode '0644'
  owner 'web_admin'
  group 'web_admin'
end
