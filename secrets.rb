Capistrano::Configuration.instance.load do
  namespace :deploy do
    namespace :secrets do

      desc <<-DESC
        Creates the secrets.js configuration file in shared path.

        By default, this task uses a template unless a template \
        called secrets.js.erb is found in the /config/deploy folder.
        The default template has no secrets. \

        When this recipe is loaded, secrets:setup is automatically configured \
        to be invoked after deploy:setup. You can skip this task setting \
        the variable :skip_secrets_setup to true. This is especially useful \
        if you are using this recipe in combination with \
        capistrano-ext/multistaging to avoid multiple secrets:setup calls \
        when running deploy:setup for all stages one by one.
      DESC
      task :setup, :except => { :no_release => true } do

        default_template = <<-EOF
        module.exports = {
        };
        EOF

        location = "config/deploy/secrets.js.erb"
        template = File.file?(location) ? File.read(location) : default_template

        config = ERB.new(template)

        run "mkdir -p #{shared_path}/config"
        put config.result(binding), "#{shared_path}/config/secrets.js"
      end

      desc <<-DESC
        [internal] Updates the symlink for secrets.js file to the just deployed release.
      DESC
      task :symlink, :except => { :no_release => true } do
        run "ln -nfs #{shared_path}/config/secrets.js #{release_path}/config/secrets.js"
      end
    end

    after "deploy:setup",           "deploy:secrets:setup"   unless fetch(:skip_secrets_setup, false)
    after "deploy:finalize_update", "deploy:secrets:symlink"

  end

end