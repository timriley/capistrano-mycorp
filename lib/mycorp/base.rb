require 'capistrano/mycorp/common'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)
  
configuration.load do
  
#
# Configuration
#

# Multistage
# _cset(:default_stage) { 'dev' }
# 
# require 'capistrano/ext/multistage'

# User details
_cset :user,          'deployer'
_cset(:group)         { user }

# Application details
_cset(:app_name)      { abort "Please specify the short name of your application, set :app_name, 'foo'" }
set(:application)     { "#{app_name}.mycorp.com" }
_cset(:runner)        { user }
_cset :use_sudo,      false

# SCM settings
_cset(:appdir)        { "/home/#{user}/deployments/#{application}" }
_cset :scm,           'git'
set(:repository)      { "git@git.mycorp.net:#{app_name}.git"}
_cset :branch,        'master'
_cset :deploy_via,    'remote_cache'
set(:deploy_to)       { appdir }

# Git settings for capistrano
default_run_options[:pty]     = true # needed for git password prompts
ssh_options[:forward_agent]   = true # use the keys for the person running the cap command to check out the app

#
# Dependencies
#

require 'capistrano/amc/config'
require 'capistrano/amc/database'
require 'capistrano/amc/assets'

depend :remote, :directory, :writeable, "/home/#{user}/deployments"

#
# Runtime Configuration, Recipes & Callbacks
#

namespace :mycorp do
  task :ensure do
    # This is to determine whether the app is behind a load balancer on another host.
    # Default to false, which means that we do expect the :internal_balancer and :external_balancer
    # roles to exist.
    _cset(:standalone) { false }
        
    self.load do
      namespace :deploy do
        namespace :web do
          if standalone
            # These tasks will run on each app server
            desc "Disable requests to the app, show maintenance page"
            task :disable, :roles => :web do
              run "ln -nfs #{current_path}/public/maintenance.html #{current_path}/public/maintenance-mode.html"
            end

            desc "Re-enable the web server by deleting any maintenance file"
            task :enable, :roles => :web do
              run "rm -f #{current_path}/public/maintenance-mode.html"
            end
          else
            # These tasks will run on the load balancers
            desc "Disable requests to the app, show maintenance page"
            task :disable, :roles => :load_balancer do
              run "touch /etc/webdisable/#{app_name}"
            end

            desc "Re-enable the web server by deleting any maintenance file"
            task :enable, :roles => :load_balancer do
              run "rm -f /etc/webdisable/#{app_name}"
            end
          end
        end
      end
    end
  end
end

# Make mycorp:ensure run immediately after the stage-specific config is loaded
# This means it can make use of variables specified in _either_ the main deploy.rb
# or any of the stage files.
on :after, "mycorp:ensure", :only => stages

#
# Recipes
#

# Deploy tasks for Passenger
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

end