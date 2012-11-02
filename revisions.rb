# See https://github.com/capistrano/capistrano/issues/168
Capistrano::Configuration::Namespaces::Namespace.class_eval do
  def capture(*args)
    parent.capture *args
  end
end

# WARNING: Run this AFTER deploy, not before, because current_revision touches the path
# based on http://madebynathan.com/2011/03/01/capistrano-task-show-deployed-revisions-diffs/
Capistrano::Configuration.instance.load do
  namespace :revisions do

    desc "List deployment changes"
    task :full, :roles => :app do
      current, previous, latest = current_revision[0,7], previous_revision[0,7], real_revision[0,7]
      puts "\n" << "-"*63
      puts "===== Master Revision: \033[1;33m#{latest}\033[0m\n\n"
      puts "===== [ \033[1;36m#{application.capitalize} - #{stage.capitalize}\033[0m ]"
      puts "=== Deployed Revision: \033[1;32m#{current}\033[0m"
      puts "=== Previous Revision: \033[1;32m#{previous}\033[0m\n\n"

      # If deployed and master are the same, show the difference between the last 2 deployments.
      base_label, new_label, base_rev, new_rev = latest != current ? \
           ["deployed", "master", current, latest] : \
           ["previous", "deployed", previous, current]

      # Show difference between master and deployed revisions.
      if (diff = `git log #{base_rev}..#{new_rev} --oneline`) != ""
        # Colorize refs
        diff.gsub!(/^([a-f0-9]+) /, "\033[1;32m\\1\033[0m - ")
        diff = "    " << diff.gsub("\n", "\n    ") << "\n"
        # Indent commit messages nicely, max 80 chars per line, line has to end with space.
        diff = diff.split("\n").map{|l|l.scan(/.{1,120}/).join("\n"<<" "*14).gsub(/([^ ]*)\n {14}/m,"\n"<<" "*14<<"\\1")}.join("\n")
        puts "=== Difference between #{base_label} revision and #{new_label} revision:\n\n"
        puts diff
      end
    end

    desc "Condensed list of deployment changes"
    task :condensed, :roles => :app do
      current, previous, latest = current_revision[0,7], previous_revision[0,7], real_revision[0,7]

      # If deployed and master are the same, show the difference between the last 2 deployments.
      base_label, new_label, base_rev, new_rev = latest != current ? \
           ["deployed", "master", current, latest] : \
           ["previous", "deployed", previous, current]

      # Show difference between master and deployed revisions.
      if (diff = `git log #{base_rev}..#{new_rev} --oneline`) != ""
        diff = "    " << diff.gsub("\n", "\n    ") << "\n"
        # Indent commit messages nicely, max 80 chars per line, line has to end with space.
        diff = diff.split("\n").map{|l|l.scan(/.{1,120}/).join("\n"<<" "*14).gsub(/([^ ]*)\n {14}/m,"\n"<<" "*14<<"\\1")}.join("\n")
        puts diff
      end
    end

    desc "Pipe condensed list of deployment changes to campfire"
    task :campfire_condensed, :roles => :app do
      config = YAML.load_file("config/campfire.yml")
      campfire = Tinder::Campfire.new config['account'],
                                      :token => config['token'],
                                      :ssl => config['ssl']
      ROOM = campfire.find_room_by_name config['room']
      current, previous, latest = current_revision[0,7], previous_revision[0,7], real_revision[0,7]

      # If deployed and master are the same, show the difference between the last 2 deployments.
      base_label, new_label, base_rev, new_rev = latest != current ? \
           ["deployed", "master", current, latest] : \
           ["previous", "deployed", previous, current]

      # Show difference between master and deployed revisions.
      if (diff = `git log #{base_rev}..#{new_rev} --oneline`) != ""
        diff = "    " << diff.gsub("\n", "\n    ") << "\n"
        # Indent commit messages nicely, max 80 chars per line, line has to end with space.
        diff = diff.split("\n").map{|l|l.scan(/.{1,120}/).join("\n"<<" "*14).gsub(/([^ ]*)\n {14}/m,"\n"<<" "*14<<"\\1")}.join("\n")
        ROOM.paste diff
      end
    end
  end
end