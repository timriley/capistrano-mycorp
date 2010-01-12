set :application, 'myapp.mycorp.com'
set :user, 'deployer'
set :deploy_to, "/home/deployer/deployments/#{application}"
set :use_sudo, false

role :app,  '192.168.0.1'
role :web,  '192.168.0.1'
role :db,   '192.168.0.1', :primary => true

set :scm, :git
set :repository, 'git@git.mycorp.net:myapp.git'
set :branch, 'master'
set :deploy_via, :remote_cache

default_run_options[:pty] = true
set :ssh_options, { :forward_agent => true }

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
end

before  'deploy:setup',       'sphinx:create_db_dir'
before  'deploy:setup',       'sphinx:generate_yaml'
after   'deploy:update_code', 'sphinx:symlink'

namespace :sphinx do
  desc 'Create a directory to store the sphinx indexes'
  task :create_db_dir, :roles => :app do
    run "mkdir -p #{shared_path}/sphinx"
  end

  desc 'Generate a config yaml in shared path'
  task :generate_yaml, :roles => :app do
    sphinx_yaml = <<-EOF
development: &base
  morphology: stem_en
  config_file: #{shared_path}/config/sphinx.conf
test:
  <<: *base
production:
  <<: *base
EOF
    run "mkdir -p #{shared_path}/config"
    put sphinx_yaml, "#{shared_path}/config/sphinx.yml"
  end
  
  desc 'Symlink the sphinx yml and config files, and the db directory for storage of indexes'
  task :symlink, :roles => :app do
    run "ln -nfs #{shared_path}/sphinx             #{release_path}/db/sphinx"
    run "ln -nfs #{shared_path}/config/sphinx.yml  #{release_path}/config/sphinx.yml"
    run "ln -nfs #{shared_path}/config/sphinx.conf #{release_path}/config/sphinx.conf"
  end
end