ENV['HOMEBREW_CASK_OPTS'] = "--appdir=/Applications"
Rake::TaskManager.record_task_metadata = true

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

def filemap(map)
  map.inject({}) do |result, (key, value)|
    result[File.expand_path(key)] = File.expand_path(value)
    result
  end.freeze
end

COPIED_FILES = filemap(
  "vimrc.local"         => "~/.vimrc.local",
  "vimrc.bundles.local" => "~/.vimrc.bundles.local",
  "tmux.conf.local"     => "~/.tmux.conf.local",
  "composer.json"       => "~/.composer/composer.json",
  "fishfile"            => "~/.config/fish/fishfile",
  "motd.sh"             => "/usr/local/bin/motd.sh",
)

LINKED_FILES = filemap(
  "vim"                             => "~/.vim",
  "tmux.conf"                       => "~/.tmux.conf",
  "vimrc"                           => "~/.vimrc",
  "vimrc.bundles"                   => "~/.vimrc.bundles",
  "net.listfeeder.UpdateBrew.plist" => "~/Library/LaunchAgents/net.listfeeder.UpdateBrew.plist",
  "docker.fish"                     => "~/.config/fish/completions/docker.fish"
)

HOMEBREW_PACKAGES = [
  "the_silver_searcher",
  "reattach-to-user-namespace",
  ["tmux", :requires => ">= 2.1"],
  "git",
  ["vim", "--with-override-system-vi"],
  ["fish", :requires => ">= 2.3"],
  "fisherman",
  "direnv",
  "dnsmasq",
  "docker",
  "docker-compose",
  "php@7.0",
  "php@7.1",
  "php",
  "composer",
  "node",
  "nvm",
  "yarn",
  "ruby",
  "rbenv",
  "ruby-build",
  "peco",
  "thefuck",
  "httpie",
  "fzf",
  "hub",
  "grc",
  "python",
]

PIP_PACKAGES = [
  "ansible",
  "bumpversion",
]

HOMEBREW_TAPS = [
  "caskroom/cask",
  "fisherman/tap",
  "homebrew/services",
  "homebrew/command-not-found",
]

CASK_PACKAGES = [
  "docker",
  "vagrant",
  "virtualbox",
]

namespace :install do
  desc "Update or Install Brew"
  task :brew do |task|
    step task.comment
    unless system('which brew > /dev/null || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"')
      raise "Homebrew must be installed before continuing."
    end
  end

  desc "Remove Old Cask Tap"
  task :cask_tap do |task|
    step task.comment
    system "brew", "untap", "phinze/cask" if system %Q{brew tap | grep phinze/cask > /dev/null}
  end

  desc "Install Homebrew Packages"
  task :homebrew_packages => [:homebrew_taps] do |task|
    step task.comment
    HOMEBREW_PACKAGES.each do |package|
      package_name = package.is_a?(Array) ? package.first : package
      puts " - #{package_name}"
      method(:brew_install).call(*package)
    end
  end

  desc "Add Homebrew Taps"
  task :homebrew_taps => [:brew, :cask_tap] do |task|
    step task.comment
    HOMEBREW_TAPS.each do |tap|
      puts " - #{tap}"
      brew_tap tap
    end
  end

  desc "Install Homebrew Casks"
  task :homebrew_casks => [:homebrew_taps] do |task|
    step task.comment
    CASK_PACKAGES.each do |package|
      puts " - #{package}"
      brew_cask_install package
    end
  end

  desc "Install PIP Packages"
  task :pip => [:homebrew_packages] do |task|
    step task.comment
    pip = "/usr/local/opt/python/libexec/bin/pip"
    PIP_PACKAGES.each do |package|
      puts " - #{package}"
      unless system "#{pip} show #{package} > /dev/null"
        sh pip, "install", package
      end
    end
  end

  desc "Copy Default Files"
  task :copy_files do |task|
    step task.comment
    COPIED_FILES.each do |orig, copy|
      puts " - #{copy}"
      parent = File.dirname copy
      mkdir_p parent unless File.exists? parent

      cp orig, copy, :verbose => true unless File.exist? copy
    end
  end

  desc "Link Static Files"
  task :link_files do |task|
    step task.comment
    LINKED_FILES.each do |orig, link|
      puts " - #{link}"
      link_file orig, link
    end
  end

  desc "Install Vundle"
  task :vundle => [:homebrew_packages] do |task|
    step task.comment
    install_github_bundle "VundleVim", "Vundle.vim"
    sh "/usr/local/bin/vim", '-c', "PluginInstall!", "-c", "q", "-c", "q"
  end

  desc "Setup Fish Friendly Interactive Shell"
  task :fish => [:homebrew_packages, :copy_files, :link_files] do |task|
    step task.comment
    puts "Changing Default Shell"
    unless IO.readlines("/etc/shells").any? /^#{Regexp.quote("/usr/local/bin/fish")}$/
      sh "sudo", "sh", "-c", "echo '\n/usr/local/bin/fish\n' >> /etc/shells"
    end
    sh "chsh", "-s", "/usr/local/bin/fish" unless ENV["SHELL"] == "/usr/local/bin/fish"
    sh "/usr/local/bin/fish", "-c", "fisher"
  end

  desc "Configure Dnsmasq"
  task :dnsmasq => [:homebrew_packages, :homebrew_taps] do |task|
    step task.comment
    unless Dir.exists?("/etc/resolver") && `brew services list`.match(/^dnsmasq\s+started/)
      puts "Create /etc/resolver and start service"
      sh "sudo", "mkdir", "-p", "/etc/resolver" unless Dir.exists? "/etc/resolver"
      sh "sudo", "brew", "services", "start", "dnsmasq" unless `brew services list`.match /^dnsmasq\s+started/
    end
  end

  desc "Install Composer Dependencies"
  task :composer => [:homebrew_packages, :copy_files] do |task|
    step task.comment
    sh "composer", "global", "install"
  end

  desc "Load Launchd Agent & Daemon"
  task :launchd => [:link_files, :copy_files, :brew] do |task|
    step task.comment
    unless File.exists? "/Library/LaunchDaemons/net.listfeeder.SetMotd.plist"
      puts "Copy SetMotd Launch Daemon"
      sh "sudo", "cp", __dir__ + "/net.listfeeder.SetMotd.plist", "/Library/LaunchDaemons/net.listfeeder.SetMotd.plist"
    end

    puts "Load SetMotd Launch Daemon"
    unless system "sudo launchctl list net.listfeeder.SetMotd > /dev/null"
      sh "sudo", "launchctl", "load", "/Library/LaunchDaemons/net.listfeeder.SetMotd.plist"
    end

    unless system "launchctl list net.listfeeder.UpdateBrew > /dev/null"
      sh "launchctl", "load", Dir.home + "/Library/LaunchAgents/net.listfeeder.UpdateBrew.plist"
    end
  end

  desc "Install Sudoers File For Vagrant"
  task :sudoers do |task|
    step task.comment
    file = __dir__ + "/sudoers_vagrant"
    unless system "visudo -cf #{file} > /dev/null"
      puts "Sudoers file failed validation; skipping!"
      return
    end

    unless File.exists? "/etc/sudoers.d/vagrant"
      puts "Copy Sudoers File"
      sh "sudo", "cp", file, "/etc/sudoers.d/vagrant"
      sh "sudo", "chown", "root:wheel", "/etc/sudoers.d/vagrant"
      sh "sudo", "chmod", "440", "/etc/sudoers.d/vagrant"
    end
  end

  # TODO: download vagrant setup?
  # Vagrant plugins
  # curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash

  task :all => [
    :brew,
    :cask_tap,
    :homebrew_taps,
    :homebrew_packages,
    :homebrew_casks,
    :pip,
    :copy_files,
    :link_files,
    :vundle,
    :fish,
    :dnsmasq,
    :composer,
    :launchd,
    :sudoers,
  ]
end

desc "Maximize your awesome"
task :install => :"install:all" do
  step "Finished!"
  puts
  puts "  Enjoy!"
  puts
end

desc "Minimize your awesome"
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
