require 'capistrano_colors'

Capistrano::Configuration.instance.load do
  after "deploy", "deploy:reminders:show"
  after "deploy", "deploy:reminders:clear"

  if defined? Capistrano::Logger.add_color_matcher
    Capistrano::Logger.add_color_matcher({ :match => /^Reminder/,  :color => :magenta, :attribute => :bright, :prio => 0 })
  end

  namespace :deploy do
    namespace :reminders do
      def reminder_file
       "#{shared_path}/system/reminders.txt"
      end

      desc "adds a reminder that will be shown on deploy in the console of the next deployer"
      task :add, :roles => :reminder_host do
        set :reminder, Capistrano::CLI.ui.ask("Reminder: ")
        run "echo \"Reminder:\" >> #{reminder_file}"
        run "echo \"user: #{user}\" >> #{reminder_file}"
        run "echo \"On: #{Time.new.to_s}\" >> #{reminder_file}"
        run "echo \"Message: #{reminder}\" >> #{reminder_file}"
        run "echo \"\n\" >> #{reminder_file}"
      end

      desc "shows all the current reminder messages"
      task :show, :roles => :reminder_host do
        run "if [ -e #{reminder_file} ]; then cat #{reminder_file}; fi"
      end

      desc "clears the current reminder messages"
      task :clear, :roles => :reminder_host do
        run "if [ -e #{reminder_file} ]; then rm #{reminder_file}; fi"
      end
    end
  end
end