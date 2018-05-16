ENV['HOMEBREW_CASK_OPTS'] = "--appdir=/Applications"

def brew_install(package, *args)
  versions = `brew list #{package} --versions`
  options = args.last.is_a?(Hash) ? args.pop : {}

  # if brew exits with error we install tmux
  if versions.empty?
    sh "brew", "install", package, *args
  elsif options[:requires]
    # brew did not error out, verify tmux is greater than 1.8
    # e.g. brew_tmux_query = 'tmux 1.9a'
    installed_version = versions.split(/\n/).first.split(' ').last
    unless version_match?(options[:requires], installed_version)
      sh "brew", "upgrade", package, args
    end
  end
end

def brew_tap(tap)
  unless system("brew tap | grep #{tap} > /dev/null") || system("brew", "tap", tap)
    raise "Failed to tap #{tap} in Homebrew."
  end
end

def version_match?(requirement, version)
  # This is a hack, but it lets us avoid a gem dep for version checking.
  # Gem dependencies must be numeric, so we remove non-numeric characters here.
  matches = version.match(/(?<versionish>\d+\.\d+)/)
  return false unless matches.length > 0
  Gem::Dependency.new('', requirement).match?('', matches.captures[0])
end

def install_github_bundle(user, package)
  unless File.exist? File.expand_path("~/.vim/bundle/#{package}")
    sh "git", "clone", "https://github.com/#{user}/#{package}", "~/.vim/bundle/#{package}"
  end
end

def brew_cask_install(package, *options)
  output = `brew cask info #{package}`
  return unless output.include?('Not installed')

  sh "brew", "cask", "install", package, *options
end

def step(description)
  description = "-- #{description} ".ljust(80, '-')
  puts
  puts "\e[32m#{description}\e[0m"
end

def app_path(name)
  path = "/Applications/#{name}.app"
  ["~#{path}", path].each do |full_path|
    return full_path if File.directory?(full_path)
  end

  return nil
end

def app?(name)
  return !app_path(name).nil?
end

def get_backup_path(path)
  number = 1
  backup_path = "#{path}.bak"
  loop do
    if number > 1
      backup_path = "#{backup_path}#{number}"
    end
    if File.exists?(backup_path) || File.symlink?(backup_path)
      number += 1
      next
    end
    break
  end
  backup_path
end

def link_file(original_filename, symlink_filename)
  original_path = File.expand_path(original_filename)
  symlink_path = File.expand_path(symlink_filename)
  if File.exists?(symlink_path) || File.symlink?(symlink_path)
    if File.symlink?(symlink_path)
      symlink_points_to_path = File.readlink(symlink_path)
      return if symlink_points_to_path == original_path
      # Symlinks can't just be moved like regular files. Recreate old one, and
      # remove it.
      ln_s symlink_points_to_path, get_backup_path(symlink_path), :verbose => true
      rm symlink_path
    else
      # Never move user's files without creating backups first
      mv symlink_path, get_backup_path(symlink_path), :verbose => true
    end
  end
  parent = File.dirname symlink_path
  mkdir_p parent unless File.exists? parent
  ln_s original_path, symlink_path, :verbose => true
end

def unlink_file(original_filename, symlink_filename)
  original_path = File.expand_path(original_filename)
  symlink_path = File.expand_path(symlink_filename)
  if File.symlink?(symlink_path)
    symlink_points_to_path = File.readlink(symlink_path)
    if symlink_points_to_path == original_path
      # the symlink is installed, so we should uninstall it
      rm_f symlink_path, :verbose => true
      backups = Dir["#{symlink_path}*.bak"]
      case backups.size
      when 0
        # nothing to do
      when 1
        mv backups.first, symlink_path, :verbose => true
      else
        $stderr.puts "found #{backups.size} backups for #{symlink_path}, please restore the one you want."
      end
    else
      $stderr.puts "#{symlink_path} does not point to #{original_path}, skipping."
    end
  else
    $stderr.puts "#{symlink_path} is not a symlink, skipping."
  end
end

namespace :install do
  desc "Update or Install Brew"
  task :brew do
    step 'Homebrew'
    unless system('which brew > /dev/null || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"')
      raise "Homebrew must be installed before continuing."
    end
  end

  desc "Install Homebrew Cask"
  task :brew_cask do
    step "Homebrew Cask"
    system "brew", "untap", "phinze/cask" if system %Q{brew tap | grep phinze/cask > /dev/null}
    brew_tap "caskroom/cask"
  end

  desc "Install The Silver Searcher"
  task :the_silver_searcher do
    step "the_silver_searcher"
    brew_install "the_silver_searcher"
  end

  desc "Install reattach-to-user-namespace"
  task :reattach_to_user_namespace do
    step "reattach-to-user-namespace"
    brew_install "reattach-to-user-namespace"
  end

  desc "Install tmux"
  task :tmux do
    step "tmux"
    # tmux copy-pipe function needs tmux >= 1.8
    brew_install "tmux", :requires => ">= 2.1"
  end

  desc "Install Git"
  task :git do
    step "git"
    brew_install "git"
  end

  desc "Install vim"
  task :vim do
    step "vim"
    brew_install "vim", "--with-override-system-vi"
  end

  desc "Install Vundle"
  task :vundle do
    step "vundle"
    install_github_bundle "VundleVim", "Vundle.vim"
    sh "/usr/local/bin/vim", '-c', "PluginInstall!", "-c", "q", "-c", "q"
  end

  desc "Install Fish"
  task :fish do
    step "Fish"
    brew_install "fish", :requires => ">= 2.3"
    brew_tap "fisherman/tap"
    brew_install "fisherman"
    puts "Changing Default Shell"
    if IO.readlines("/etc/shells").grep(Regexp.quote "/usr/local/bin/fish").empty?
      sh "sudo", "sh", "-c", "echo '\n/usr/local/bin/fish' >> /etc/shells"
    end
    sh "chsh", "-s", "/usr/local/bin/fish" unless ENV["SHELL"] == "/usr/local/bin/fish"
    sh "/usr/local/bin/fish", "-c", "fisher"
  end

  desc "Install Direnv"
  task :direnv do
    step "Direnv"
    brew_install "direnv"
  end

  desc "Install Dnsmasq"
  task :dnsmasq do
    step "Dnsmasq"
    brew_install "dnsmasq"
    brew_tap "homebrew/services"
    puts "Create /etc/resolver and start service" unless Dir.exists?("/etc/resolver") && `brew services list`.match(/^dnsmasq\s+started/)
    sh "sudo", "mkdir", "-p", "/etc/resolver" unless Dir.exists? "/etc/resolver"
    sh "sudo", "brew", "services", "start", "dnsmasq" unless `brew services list`.match /^dnsmasq\s+started/
  end

  desc "Install Docker"
  task :docker do
    step "Docker"
    brew_install "docker"
    brew_install "docker-compose"
    brew_cask_install "docker"
  end

  desc "Install PHP"
  task :php do
    step "PHP"
    brew_install "php@7.0"
    brew_install "php@7.1"
    brew_install "php"
    brew_install "composer"

    sh "composer", "global", "install"
  end

  desc "Install Vagrant"
  task :vagrant do
    step "Vagrant"
    brew_cask_install "vagrant"
  end

  desc "Install VirtualBox"
  task :virtualbox do
    step "VirtaulBox"
    brew_cask_install "virtualbox"
  end

  desc "Install Node"
  task :node do
    step "Node.js"
    brew_install "node"
    brew_install "nvm"
    brew_install "yarn"
  end

  desc "Install Ruby"
  task :ruby do
    step "Ruby"
    brew_install "ruby"
    brew_install "rbenv"
    brew_install "ruby-build"
  end

  desc "Install Peco"
  task :peco do
    step "Peco"
    brew_install "peco"
  end

  desc "Install The Fuck"
  task :thefuck do
    step "The Fuck"
    brew_install "thefuck"
  end

  desc "Install Httpie"
  task :httpie do
    step "Httpie"
    brew_install "httpie"
  end

  desc "Install Fzf"
  task :fzf do
    step "Fzf"
    brew_install "fzf"
  end

  desc "Install Hub"
  task :hub do
    step "Hub"
    brew_install "hub"
  end

  desc "Install Grc"
  task :grc do
    step "Grc"
    brew_install "grc"
  end

  desc "Install Brew Command Not Found"
  task :command_not_found do
    step "Brew Command Not Found"
    brew_tap "homebrew/command-not-found"
  end

  # TODO: Add stuff about motd launch daemon (if I can remember the syntax for all that junk)
  # download vagrant setup?
  # Vagrant plugins
end

def filemap(map)
  map.inject({}) do |result, (key, value)|
    result[File.expand_path(key)] = File.expand_path(value)
    result
  end.freeze
end

COPIED_FILES = filemap(
  "vimrc.local"                          => "~/.vimrc.local",
  "vimrc.bundles.local"                  => "~/.vimrc.bundles.local",
  "tmux.conf.local"                      => "~/.tmux.conf.local",
  "composer.json"                        => "~/.composer/composer.json",
  "fishfile"                             => "~/.config/fish/fishfile",
  "motd.sh"                              => "/usr/local/bin/motd.sh",
  "net.listfeeder.home.UpdateBrew.plist" => "~/Library/LaunchDaemons/net.listfeeder.home.UpdateBrew.plist"
)

LINKED_FILES = filemap(
  "vim"           => "~/.vim",
  "tmux.conf"     => "~/.tmux.conf",
  "vimrc"         => "~/.vimrc",
  "vimrc.bundles" => "~/.vimrc.bundles",
  "docker.fish"   => "~/.config/fish/completions/docker.fish"
)

desc "Install these config files."
task :install do
  Rake::Task["install:brew"].invoke
  Rake::Task["install:brew_cask"].invoke
  Rake::Task["install:git"].invoke
  Rake::Task["install:the_silver_searcher"].invoke
  Rake::Task["install:reattach_to_user_namespace"].invoke
  Rake::Task["install:tmux"].invoke
  Rake::Task["install:vim"].invoke
  Rake::Task["install:direnv"].invoke
  Rake::Task["install:dnsmasq"].invoke
  Rake::Task["install:docker"].invoke
  Rake::Task["install:vagrant"].invoke
  # Rake::Task["install:virtualbox"].invoke ## This bombs out in our test VM until you unblock its extension
  Rake::Task["install:node"].invoke
  Rake::Task["install:ruby"].invoke
  Rake::Task["install:peco"].invoke
  Rake::Task["install:thefuck"].invoke
  Rake::Task["install:httpie"].invoke
  Rake::Task["install:fzf"].invoke
  Rake::Task["install:hub"].invoke
  Rake::Task["install:grc"].invoke

  step "symlink"
  LINKED_FILES.each do |orig, link|
    link_file orig, link
  end

  COPIED_FILES.each do |orig, copy|
    parent = File.dirname copy
    mkdir_p parent unless File.exists? parent

    cp orig, copy, :verbose => true unless File.exist? copy
  end

  # Install Vundle and bundles
  Rake::Task["install:vundle"].invoke
  Rake::Task["install:fish"].invoke
  Rake::Task["install:php"].invoke

  step "Finished!"
  puts
  puts "  Enjoy!"
  puts
end

desc "Uninstall these config files."
task :uninstall do
  step "un-symlink"

  # un-symlink files that still point to the installed locations
  LINKED_FILES.each do |orig, link|
    unlink_file orig, link
  end

  # delete unchanged copied files
  COPIED_FILES.each do |orig, copy|
    rm_f copy, :verbose => true if File.read(orig) == File.read(copy)
  end

  step "homebrew"
  puts
  puts "Manually uninstall homebrew if you wish: https://gist.github.com/mxcl/1173223."

  step "iterm2"
  puts
  puts "Run this to uninstall iTerm:"
  puts
  puts "  rm -rf /Applications/iTerm.app"

  step "macvim"
  puts
  puts "Run this to uninstall MacVim:"
  puts
  puts "  rm -rf /Applications/MacVim.app"
end

task :default => :install
