require 'stringio'

class Command

  def self.inherited(subclass)
    @@subclasses ||= []
    @@subclasses << subclass unless subclass == DefaultCommand
  end

  def self.commands
    @@subclasses.map do |clazz|
      clazz.new(nil).name
    end.sort
  end

  def self.load(repl, command_line)
    if command_line.start_with?('!')
      # load custom command
      command_parts = command_line[1..-1].split
      command_name = command_parts.first
      command_args = command_parts[1..-1]
      command_class = "#{command_name.capitalize}Command"
      begin
        clazz = Object.const_get(command_class)
        clazz.new(repl, command_args)
      rescue NameError => e
        nil
      end
    else
      DefaultCommand.new(repl, Array(command_line.strip))
    end
  end

  attr_reader :args

  def initialize(repl, args = [])
    @repl = repl
    @args = args
  end

  def name
    "!#{self.class.name.gsub("Command", "").downcase}"
  end

  def execute
    if valid_args?
      run
    else
      puts "Invalid arguments. Ex.: #{usage}"
    end
  end

  private

  def usage
    "#{name} #{sample_args}"
  end

  def sample_args
  end

  def valid_args?
    true
  end

end

class DefaultCommand < Command

  def run
    begin
      cmd = "#{adb} #{args}"

      if interactive?
        system cmd
      else
        if package_dependent?
          cmd << " #{@repl.default_package}" if @repl.default_package
        end
        res = `#{cmd}`
        puts res
        res
      end
    end
  end

  def args
    @args.first
  end

  private

  def adb
    adb = "#{REPL::ADB}"
    adb << " -s #{@repl.default_device}" if @repl.default_device
    adb
  end

  def interactive?
    ["logcat", "shell"].include?(args)
  end

  def package_dependent?
    ["uninstall"].include?(args)
  end
end

class DevicesCommand < DefaultCommand
  def args
    "devices"
  end

  def run
    device_list = super.lines.find_all { |l| /device$/ =~ l }.map { |l| l.gsub("device", "").strip }
    puts device_list.inspect if @repl.debug?
    device_list
  end
end

class PackageCommand < Command

  def sample_args
    "com.mydomain.mypackage"
  end

  def valid_args?
    args.length == 1 && /^\w+(\.\w+)*$/ =~ args.first
  end

  def run
    default_package = args.first
    puts "Setting default package to #{default_package.inspect}"
    @repl.default_package = default_package
  end
end

class DeviceCommand < Command
  def sample_args
    "emulator-5554"
  end

  def valid_args?
    args.length == 1 && @repl.devices.include?(args.first.strip)
  end

  def run
    default_device = args.first
    puts "Setting default device to #{default_device.inspect}"
    @repl.default_device = default_device
  end
end

class ResetCommand < Command

  def valid_args?
    args.empty?
  end

  def run
    @repl.default_device = nil
    @repl.default_package = nil
  end

end

class ListCommand < Command
  def valid_args?
    args.empty?
  end

  def run
    puts Command.commands.join("\n")
  end
end
