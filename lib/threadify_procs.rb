require "threadify_procs/version"

module ThreadifyProcs

  def call_with_threads procs, options={}
    set_procs procs
    return if procs.blank?
    set_options options
    with_writer_thread do
      launch_procs
    end
  end

  private

  def launch_writer_thread
    @writer_thread = Thread.new do
      begin
        while true do
          unless @files_to_write.empty?
            data = @files_to_write.shift
            filename, string = data
            File.open(filename, 'w') do |file|
              file.binmode
              file.write string
            end
          else
            break if ready_to_kill_writer_thread?
          end
        end
      rescue => exception
        Thread.main.raise exception
      end
    end
  end

  def kill_writer_thread
    @kill_writer_thread = true
    @writer_thread.join
  end

  def launch_procs
    @threads = [].tap do |threads|
      groups_of_procs.each do |procs|
        threads << Thread.new do
          procs.each(&:call)
        end
      end
    end
    @threads.each(&:join)
  end

  def set_procs procs
    unless procs.kind_of?(Array) && procs.all?{|_proc|_proc.kind_of?(Proc)}
      raise 'ThreadifyProcs expects an array of procs.'
    end
    @procs = procs
  end

  def set_options options
    @number_of_threads = options[:number_of_threads].to_i || 25
    if @number_of_threads < 1
      raise 'ThreadifyProcs expects a positive number of Threads.'
    end
    @procs_per_thread = (@procs.size / @number_of_threads.to_f).ceil
    @with_writer = !!options[:with_writer]
  end

  def with_writer_thread
    begin
      launch_writer_thread if @with_writer
      yield
    ensure
      kill_writer_thread if @with_writer
    end
  end

  def groups_of_procs
    [].tap do |groups|
      while !@procs.empty? do
        groups << @procs.shift(@procs_per_thread)
      end
    end
  end

  def ready_to_kill_writer_thread?
    @kill_writer_thread && @files_to_write.empty? && @threads.all?(&:stop?)
  end
end
