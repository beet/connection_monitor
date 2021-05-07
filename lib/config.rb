=begin

The thing that knows about the command line args, turning them into a config
hash, and persisting it to the DB.

["--debug", "--verbal-alerts=false"]

=end
require "yaml"

class Config
  attr_reader :defaults, :base_dir, :config

  def initialize(defaults:, base_dir:)
    @defaults = defaults
    @base_dir = base_dir
    @config = {}
  end

  def read
    return unless File.exist?(config_file)

    apply_config(
      YAML.load(File.read(config_file))
    )
  end

  def update(args)
    read || apply_default_config

    process_config_from(args)

    write_config

    config
  end

  private

  def write_config
    File.open(config_file, "wb") do |file|
      # file << YAML.dump(config_vars_to_hash)
      file << YAML.dump(config)
    end
  end

  def config_file
    "#{base_dir}/config.yml"
  end

  def apply_default_config
    apply_config(defaults)
  end

  # TODO: sanitise the attribute names against defaults?
  def apply_config(config_data)
    config.merge!(config_data)
  end

  def process_config_from(args)
    apply_config(
      hash_from_args_for(args, defaults.keys)
    )
  end

  def hash_from_args_for(args, keys)
    {}.tap do |hash|
      args_for_keys(args, keys).each do |arg|
        hash[key_from(arg)] = value_from(arg)
      end
    end
  end

  def args_for_keys(args, keys)
    args.select do |arg|
      keys.include?(key_from(arg))
    end
  end

  def key_from(arg)
    arg.split("=").first.sub("--", "").gsub("-", "_").to_sym
  end

  def value_from(arg)
    arg.split("=").last
  end
end
