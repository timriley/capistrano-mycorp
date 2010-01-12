set :app_name, 'myapp'

role :app,  '192.168.0.1'
role :web,  '192.168.0.1'
role :db,   '192.168.0.1', :primary => true

require 'capistrano/mycorp/base'
require 'capistrano/mycorp/thinking_sphinx'