Capistrano::Configuration.instance.load do
  namespace :deploy do
    desc "Install npm dependencies"
    task :dependencies, :roles => [:web, :app] do
      # Install the modules into the shared modules folder
      run "cd #{shared_path}; cp #{release_path}/package.json .; npm install --production --mongodb:native;"

      # Symlink the shared modules to the current release
      run "ln -nfs #{shared_path}/node_modules #{release_path}/node_modules"
    end
  end
end