require "yaml"
require_relative "#{__dir__}/predicate_attributes"

=begin

The thing that knows about the command line args, turning them into a config
hash, and persisting it to the DB:

    config = Config.new(
      defaults: {
        verbal_alerts: false,
        visual_alerts: true
      },
      base_dir: "dir/to/persist/the/config/file"
    )

To update the config hash and write it to a YAML file:

    config.update(verbal_alerts: true)
    => { verbal_alerts: true, visual_alerts: true}

To read the config hash from the YAML file:

    config.read
    => { verbal_alerts: true, visual_alerts: true}

## Predicate method accessors and getter methods

Each key in the config hash can be access with a corresponding predicate method:

    config.update(visual_alerts: false)

    config.visual_alerts?
    => false

For non-boolean attributes:

    config.update(foo: "bar")

    config.foo?
    => "bar"

    config.foo
    => "bar"

=end
class Config
  include PredicateAttributes

  attr_reader :defaults, :base_dir, :config, :config_file

  def initialize(defaults:, base_dir:)
    @defaults = defaults
    @base_dir = base_dir
    @config = {}
    @config_file = "#{base_dir}/config.yml"
  end

  # Read config hash from a YAML file
  def read
    return unless File.exist?(config_file)

    apply_config(
      YAML.load(File.read(config_file))
    )
  end

  # Update the config hash from an array of args like ["--debug",
  # "--verbal-alerts=false"], and write it to a YAML file.
  def update(args)
    read || apply_default_config

    process_config_from(args)

    write_config

    config
  end

  def show
    puts "Config from #{config_file}:\n\n"

    read.each_pair do |key, value|
      puts "#{key}: #{value}"
    end
  end

  private

  def write_config
    File.open(config_file, "wb") do |file|
      # file << YAML.dump(config_vars_to_hash)
      file << YAML.dump(config)
    end
  end

  def apply_default_config
    apply_config(defaults)
  end

  # TODO: sanitise the attribute names against defaults?
  def apply_config(config_data)
    config.merge!(config_data)

    config.each_pair do |attribute, value|
      instance_variable_set("@#{attribute}", value)
    end
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
