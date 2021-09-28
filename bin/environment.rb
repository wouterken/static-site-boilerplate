
require 'bundler/inline'
require 'shellwords'

gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'dotenv'
  gem 'launchy'
end

Dotenv.overload("bin/.env")

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options] environment"

  opts.on("-q", "--quiet", "Run Quietly") do |q|
    options[:quiet] = q
  end
  opts.on("-a", "--auto-approve", "Auto Approve") do |a|
    options[:auto_approve] = a
  end
end.parse!

unless @environment = ARGV.first
  puts "No environment given. Aborting"
  exit(1)
end
require 'optparse'

@verbose = !options[:quiet]
@auto_approve = options[:auto_approve] ? "-auto-approve " : ""
@suppress = @verbose ? "" : " > /dev/null 2>&1"

config_file_path = "./environments/#{@environment}.json"

unless File.exists?(config_file_path)
  puts "Environment config file #{config_file_path} does not exist"
  exit(1)
end

@config = nil

begin
  @config = JSON.parse(IO.read(config_file_path))
rescue StandardError => err
  puts "Invalid JSON in config file #{err}"
  exit(1)
end

unless @config['fqdn']
  puts "No key for 'fqdn' in config file."
  exit(1)
end

@tf_vars = %Q{export \
TF_VAR_fqdn=#{Shellwords.escape(@config['fqdn'])} \
TF_VAR_cloudflare_zone_id=#{Shellwords.escape(@config['cloudflare_zone_id'])} \
TF_VAR_sub=#{Shellwords.escape(@config['sub'])} \
TF_VAR_spa_routing=#{Shellwords.escape(@config['spa_routing'])}
}.strip

@terraform_dir = Shellwords.escape(File.expand_path("./../terraform", __dir__))


def cmd(command, capture: false)
  puts command if @verbose
  capture ? `#{command}#{@suppress}` : system("#{command}#{@suppress}")
end


def tf_cmd(command, capture: false)
  cmd("#{@tf_vars} && terraform -chdir=#{@terraform_dir} workspace select #{@environment}#{@suppress} && terraform -chdir=#{@terraform_dir} #{command}#{@suppress}", capture: capture)
end
