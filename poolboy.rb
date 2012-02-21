require 'pry'
require 'trollop'
require 'yaml'
require 'openssl'
require 'net/smtp'

class Options
  attr_reader :options

  def initialize(*options)
    @options = config_options
    @options.merge! arg_options do |key, oldval, newval|
      oldval unless oldval.nil?
    end
  end

  def arg_options
    opts = Trollop::options do
      opt :email, "Email address", :type => :string
      opt :email_password, "Email password", :type => :string
      opt :email_server, "Email server", :type => :string
      opt :send_email, "Include to send email with status"
      opt :pools, "Pools to run against", :type => :strings
    end
  end

  def config_options
    config_file = File.join(ENV['HOME'], '.zpool_status.yaml')
    option_set = { }
    if File.exists? config_file
      option_set = YAML.load_file(config_file)
    end
    option_set.each_with_object({}) do |(key, value), hash|
      hash[key.to_sym] = value
    end
  end
end

class Pool_Email

  def initialize(options)
    @options = options

    @smtp = Net::SMTP.new('smtp.gmail.com', 465)
    @smtp.enable_tls
  end

  def send_email(message)
    return unless use_email?
    begin
      @smtp.start(@options[:email_server], @options[:email], @options[:email_password], :plain) do |s|
        s.send_message message,
        @options[:email],
        @options[:email]
      end
    rescue Exception => error
      $stderr.puts "An error occurred sending an email: " + error.to_s
    end
  end

  def use_email?
    should_send = @options.has_key?(:send_email) && @options[:send_email]
    has_settings = [:email, :email_password, :email_server].all? { |option| !(@options[option].nil? || @options[option].empty?) }
    $stderr.puts("send_email option must be included if you wish to send email") if !should_send && has_settings
    $stderr.puts("email, email_password, and email_server must be set if you wish to send email") if should_send && !has_settings
    should_send && has_settings
  end
end

class Poolboy
  def initialize(option)
    @options = option.options
    @email = Pool_Email.new(@options)
  end

  def clean
    if(@options[:pools].nil? || @options[:pools].empty?)
      $stderr.puts "Pools need to be defined by -pools or :pools in .zpool_status.yaml"
      exit
    end

    @options[:pools].each do |pool|
      start_scrub(pool)
      wait_time = pool_wait_time(pool)
      while(wait_time.to_i > 0)
        sleep_time = wait_time <= 300 ? wait_time : 300
        sleep(sleep_time)
        wait_time = pool_wait_time pool
      end
      puts pool_status pool
    end

    send_email_for_pools
  end

  private
  def start_scrub(pool_name)
    `zpool scrub #{pool_name}`
  end

  def pool_status(pool_name)
    `zpool status -v #{pool_name}`
  end

  def wait_time(status)
    full, day, hour, min = *status.match(/(\d*d)?(\d*h)?(\d*m)? to go/)
    totalSec = day.to_i * (24 * 60 * 60) +
               hour.to_i * (60 * 60) +
               min.to_i * 60
  end

  def pool_wait_time(pool_name)
    wait_time pool_status(pool_name)
  end

  def send_email_for_pools
    status = ""
    @options[:pools].each do |pool|
      status += pool_status(pool) + "\n"
    end
    @email.send_email(status)
  end
end

poolboy = Poolboy.new(Options.new)
poolboy.clean
