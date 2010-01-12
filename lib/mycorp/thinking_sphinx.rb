require 'capistrano/mycorp/common'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do
  
_cset(:app_name) { abort "Please specify the short name of your application, set :app_name, 'foo'" }

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
development: &main_settings
  config_file: #{shared_path}/config/sphinx.conf
  pid_file: #{shared_path}/pids/sphinx.pid
production:
  <<: *main_settings
EOF
    put sphinx_yaml, "#{shared_path}/config/sphinx.yml"
  end
  
  desc 'Symlink the sphinx yml and config files, and the db directory for storage of indexes'
  task :symlink, :roles => :app do
    run "ln -nfs #{shared_path}/sphinx             #{release_path}/db/sphinx"
    run "ln -nfs #{shared_path}/config/sphinx.yml  #{release_path}/config/sphinx.yml"
    run "ln -nfs #{shared_path}/config/sphinx.conf #{release_path}/config/sphinx.conf"
  end
end

end