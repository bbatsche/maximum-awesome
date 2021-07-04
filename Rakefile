require "etc"
require "socket"

ENV['HOMEBREW_CASK_OPTS'] = "--appdir=/Applications"
Rake::TaskManager.record_task_metadata = true

def brew_install_all(packages)
  packages = packages.select { |pkg| `brew list #{pkg} --versions`.empty? }

  sh "brew", "install", *packages unless packages.empty?
end

def brew_install_single(package, *args)
  versions = `brew list #{package} --versions`

  sh "brew", "install", package, *args if versions.empty?
end

def brew_tap(tap)
  unless system("brew tap | grep #{tap} > /dev/null") || system("brew", "tap", tap)
    raise "Failed to tap #{tap} in Homebrew."
  end
end

def vagrant_plugin(plugin)
  sh "vagrant", "plugin", "install", plugin unless system "vagrant plugin list | grep #{plugin} > /dev/null"
end

def version_match?(requirement, version)
  # This is a hack, but it lets us avoid a gem dep for version checking.
  # Gem dependencies must be numeric, so we remove non-numeric characters here.
  matches = version.match(/(?<versionish>\d+\.\d+)/)
  return false unless matches.length > 0
  Gem::Dependency.new('', requirement).match?('', matches.captures[0])
end

def install_github_bundle(user, package)
  git_clone "https://github.com/#{user}/#{package}", "~/.vim/bundle/#{package}"
end

def git_clone(url, path)
  sh "git", "clone", url, File.expand_path(path) unless File.exist? File.expand_path(path)
end

def brew_cask_install(package, *options)
  output = `brew info --cask #{package}`
  return unless output.include?('Not installed')

  sh "brew", "install", "--cask", package, *options
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
  parent = File.dirname symlink_path
  mkdir_p parent unless File.exists? parent
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
  "motd.sh"             => "/usr/local/bin/motd.sh",
  "ssh_config"          => "~/.ssh/config",
  "tm_properties"       => "~/.tm_properties",
  "gitconfig"           => "~/.gitconfig",
)

LINKED_FILES = filemap(
  "vim"                             => "~/.vim",
  "tmux.conf"                       => "~/.tmux.conf",
  "vimrc"                           => "~/.vimrc",
  "vimrc.bundles"                   => "~/.vimrc.bundles",
  "net.listfeeder.UpdateBrew.plist" => "~/Library/LaunchAgents/net.listfeeder.UpdateBrew.plist",
  "conf.dockerps"                   => "~/.grc/conf.dockerps",
  "gitignore"                       => "~/.config/git/ignore",
)

HOMEBREW_PACKAGES = [
  "awscli",
  "bat",
  "composer",
  "coreutils",
  "direnv",
  "dnsmasq",
  "drone",
  "exa",
  "fish",
  "fisherman",
  "gh",
  "git",
  "go",
  "grc",
  "groovy",
  "helm",
  "httpie",
  "hub",
  "iperf3",
  "jpeg",
  "jq",
  "kubernetes-cli",
  "minikube",
  "mutagen",
  "mysql-client",
  "node",
  "nvm",
  "openjdk",
  "peco",
  "php",
  "php@7.2",
  "php@7.3",
  "php@7.4",
  "pstree",
  "python",
  "rbenv",
  "rbenv-bundle-exec",
  "rbenv-vars",
  "reattach-to-user-namespace",
  "ruby",
  "ruby-build",
  "svn",
  "terminal-notifier",
  "thefuck",
  "the_silver_searcher",
  "tmux",
  "travis",
  "unison",
  "unrpyc",
  "vim",
  "webp",
  "wget",
  "yarn",
]

PIP_PACKAGES = [
  "ansible",
  "bumpversion",
  "unrpa",
]

HOMEBREW_TAPS = [
  "bbatsche/cask-adobe-fonts",
  "bbatsche/misc",
  "drone/drone",
  "github/gh",
  "homebrew/cask",
  "homebrew/cask-fonts",
  "homebrew/cask-versions",
  "homebrew/command-not-found",
  "homebrew/services",
  "mutagen-io/mutagen",
]

DEPRECATED_TAPS = [
  "caskroom/cask",
  "fisherman/tap",
  "phinze/cask",
]

CASK_PACKAGES = [
  "1password-cli",
  "adoptopenjdk",
  "bbatsche/cask-adobe-fonts/font-source-code-pro",
  "bbatsche/cask-adobe-fonts/font-source-sans",
  "bbatsche/cask-adobe-fonts/font-source-serif",
  "docker",
  "font-comic-neue",
  "font-hasklig",
  "font-hasklug-nerd-font",
  "font-sauce-code-pro-nerd-font",
  "growlnotify",
  "renpy",
  "vagrant",
  "vagrant-vmware-utility",
  "webpquicklook",
  # "virtualbox", ## Nope, still crashes the process. Need to run manually.
]

VAGRANT_PLUGINS = [
  "vagrant-auto_network",
  "vagrant-dns",
  "vagrant-dnsmasq",
  "vagrant-vbguest",
  "vagrant-vmware-desktop",
  "vagrant-pristine",
]

GITHUB_REPOS = {
  "bbatsche/BeBat-Fish-Defaults" => "~/Repos/Fish-Defaults",
  "bbatsche/Fish-Prompt-BeBat" => "~/Repos/Fish-Prompt",
  "bbatsche/Vagrant-Setup" => "~/Vagrant",
}

FISHER_PLUGINS = [
  "danhper/fish-ssh-agent",
  "edc/bass",
  "evanlucas/fish-kubectl-completions",
  "FabioAntunes/fish-nvm",
  "franciscolourenco/done",
  "halostatue/fish-docker",
  "halostatue/fish-macos",
  "halostatue/fish-rake",
  "jorgebucaran/fisher",
  "joseluisq/gitnow",
  "laughedelic/pisces",
  "lfiolhais/plugin-homebrew-command-not-found",
  "oh-my-fish/plugin-aws",
  "oh-my-fish/plugin-bak",
  "oh-my-fish/plugin-brew",
  "oh-my-fish/plugin-bundler",
  "oh-my-fish/plugin-composer",
  "oh-my-fish/plugin-extract",
  "oh-my-fish/plugin-gem",
  "oh-my-fish/plugin-gityaw",
  "oh-my-fish/plugin-grc",
  "oh-my-fish/plugin-hash",
  "oh-my-fish/plugin-peco",
  "oh-my-fish/plugin-rbenv",
  "oh-my-fish/plugin-thefuck",
  "oh-my-fish/plugin-tmux",
  "oh-my-fish/plugin-virtualfish",
  "rominf/omf-plugin-hub",
  "spacekookie/omf-color-manual",
  "~/Repos/Fish-Defaults",
  "~/Repos/Fish-Prompt",
  "~/Repos/plugin-tab",
]

namespace :install do
  desc "Update or Install Brew"
  task :brew do |task|
    step task.comment
    unless system('which brew > /dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"')
      raise "Homebrew must be installed before continuing."
    end
  end

  desc "Remove Old Taps"
  task :deprecated_taps => [:brew] do |task|
    step task.comment
    DEPRECATED_TAPS.each do |tap|
      puts " - #{tap}"
      system "brew", "untap", tap if system %Q{brew tap | grep #{tap} > /dev/null}
    end
  end

  desc "Install Homebrew Packages"
  task :homebrew_packages => [:homebrew_taps] do |task|
    step task.comment
    brew_install_all HOMEBREW_PACKAGES
  end

  desc "Add Homebrew Taps"
  task :homebrew_taps => [:brew, :deprecated_taps] do |task|
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
    pip = "/usr/local/bin/pip3"
    PIP_PACKAGES.each do |package|
      puts " - #{package}"
      unless system "#{pip} show #{package} > /dev/null"
        sh pip, "install", package
      end
    end
  end

  desc "Install Vagrant Plugins"
  task :vagrant_plugins => [:homebrew_casks, :homebrew_packages, :dnsmasq] do |task|
    step task.comment
    VAGRANT_PLUGINS.each do |plugin|
      puts " - #{plugin}"
      vagrant_plugin plugin
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
  task :fish => [:homebrew_packages, :copy_files, :link_files, :git_clone] do |task|
    step task.comment
    puts "Changing Default Shell"
    if IO.readlines("/etc/shells").grep(/^#{Regexp.quote("/usr/local/bin/fish")}$/).empty?
      sh "sudo", "sh", "-c", "echo '\n/usr/local/bin/fish\n' >> /etc/shells"
    end
    sh "chsh", "-s", "/usr/local/bin/fish" unless ENV["SHELL"] == "/usr/local/bin/fish"

    cmd = ["fisher", "install"] | FISHER_PLUGINS
    sh "/usr/local/bin/fish", "-c", cmd.join(" ")
  end

  desc "Configure Dnsmasq"
  task :dnsmasq => [:homebrew_packages, :homebrew_taps] do |task|
    step task.comment
    unless Dir.exists?("/etc/resolver") && `sudo brew services list`.match(/^dnsmasq\s+started/)
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

      puts "Secure Motd Script"
      sh "sudo", "chmod", "740", "/usr/local/bin/motd.sh"
      sh "sudo", "chown", "root:wheel", "/usr/local/bin/motd.sh"
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

  desc "Allow Touch ID for sudo"
  task :touchid do |task|
    step task.comment

    lines = File.readlines "/etc/pam.d/sudo"

    unless lines[1].strip.end_with? "pam_tid.so"
      lines = lines.insert 1, "auth sufficient pam_tid.so\n"

      sh "sudo", "sh", "-c", "echo \"#{lines.join}\" > /etc/pam.d/sudo"
    end
  end

  desc "Install iTerm Integration"
  task :iterm => [:fish] do |task|
    step task.comment

    unless File.exists? File.expand_path("~/.iterm2_shell_integration.fish")
      sh "curl -L https://iterm2.com/shell_integration/fish -o ~/.iterm2_shell_integration.fish"
    end
  end

  desc "Generate SSH Key"
  task :ssh_key => [:copy_files] do |task|
    step task.comment

    unless File.exists?(File.expand_path "~/.ssh/id_ed25519") && File.exists?(File.expand_path "~/.ssh/id_ed25519.pub")
      default_user = Etc.getlogin
      default_host = Socket.gethostname

      print "Username (default \"#{default_user}\"): "
      input_user = STDIN.gets.strip

      print "Hostname (default \"#{default_host}\"): "
      input_host = STDIN.gets.strip

      user = input_user.empty? ? default_user : input_user
      host = input_host.empty? ? default_host : input_host

      sh "ssh-keygen", "-t", "ed25519", "-a", "100", "-C", "#{user}@#{host}", "-f", File.expand_path("~/.ssh/id_ed25519")
    end
  end

  desc "Clone Repositories"
  task :git_clone => [:homebrew_packages] do |task|
    step task.comment

    GITHUB_REPOS.each do |repo, path|
      puts " - #{repo}"

      git_clone "https://github.com/#{repo}.git", path
    end
  end

  task :all => [
    :homebrew_packages,
    :homebrew_casks,
    :pip,
    :copy_files,
    :link_files,
    :vundle,
    :fish,
    :vagrant_plugins,
    :composer,
    :iterm,
    :ssh_key,
    :launchd,
    :sudoers,
    :touchid,
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
