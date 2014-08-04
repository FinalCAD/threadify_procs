require "threadify_procs/version"

module ThreadifyProcs

  def call_with_threads procs, options={}
    set_procs procs
    set_options options
    with_writter_thread do
      launch_procs
    end
  end

  private

  def launch_writer_thread
    @writer_thread = Thread.new do
      while true do
        if data = @files_to_write.pop
          filename, string = data
          File.open(filename, 'w') do |file|
            file.binmode
            file.write string
          end
        end
      end
    end
  end

  def kill_writer_thread
    while true do
      if @files_to_write.empty?
        @writer_thread.kill
        break
      end
    end
  end

  def launch_procs
    [].tap do |threads|
      groups_of_procs.each do |procs|
        threads << Thread.new do
          procs.each(&:call)
        end
      end
    end.each(&:join)
  end

  def set_procs
    @procs = procs
    unless procs.kind_of?(Array) && procs.all?{|_proc|_proc.kind_of?(Proc)}
      raise 'ThreadifyProcs expects an array of procs.'
    end
  end

  def set_options
    @number_of_threads = options[:number_of_threads].to_i || 25
    if @number_of_threads < 1
      raise 'ThreadifyProcs expects a positive number of Threads.'
    end
    @procs_per_thread = (procs.size / @number_of_threads).ceil
    @with_writter = !!options[:with_writter]
    @files_to_write = [] if @with_writter
  end

  def with_writter_thread
    begin
      launch_writer_thread if @with_writter
      yield
    ensure
      kill_writer_thread if @with_writter
    end
  end

  def groups_of_procs
    [].tap do |groups|
      while @procs.present? do
        groups << @procs.shift(@procs_per_thread)
      end
    end
  end
end
