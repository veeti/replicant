class Command
  attr_reader :backtick_capture
  attr_reader :system_capture
  # capture system calls on all commands
  def `(cmd)
    @backtick_capture = cmd
    nil
  end
  def system(cmd)
    @system_capture = cmd
    nil
  end
end

class CommandSpecBase < MiniTest::Spec

  before do
    @repl = Replicant::REPL.new
  end

  def silent(command)
    def command.output(s)
      @output = s
    end
    def command.output_capture
      @output
    end
    command
  end
end