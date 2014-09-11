require 'spec_helper'
require 'fileutils'

class ThreadifiedJob
  include ThreadifyProcs
  attr_reader :total

  def initialize(options={})
    @options = { number_of_threads: 2 }.merge options
    @total = 0
  end

  def executed_function; end
  def procs
    [].tap do |_procs|
      3.times do |n|
        _procs << Proc.new do
          @total += n+1
          executed_function
        end
      end
    end
  end

  def launch
    call_with_threads procs, @options
  end
end

class ThreadifiedJobWithWriter < ThreadifiedJob

  def procs
    [].tap do |_procs|
      3.times do |n|
        _procs << Proc.new do
          @files_to_write << ["#{File.dirname(__FILE__)}/../tmp/#{n}.txt", n]
        end
      end
    end
  end

  def launch
    @files_to_write = []
    call_with_threads procs, number_of_threads: 3, with_writer: true
  end
end

describe ThreadifyProcs do
  let(:tmp_dir) { "#{File.dirname(__FILE__)}/../tmp" }

  describe 'call_with_threads' do
    subject{ job.launch }

    context 'with 2 threads' do
      let(:job) { ThreadifiedJob.new }
      it 'should create threads from procs' do
        subject
        expect(job.total).to eq 6
      end
    end

    context 'with callback' do
      let(:job) do
        ThreadifiedJob.new(callback: Proc.new { Struct.new(:success) })
      end
      it 'should call the callback after the procs' do
        expect(job).to receive(:executed_function).exactly(3).times.ordered
        expect(Struct).to receive(:new).with(:success).ordered
        subject
      end
    end

    context 'with_writer' do
      let(:job) { ThreadifiedJobWithWriter.new }
      before { FileUtils.mkdir tmp_dir}
      after { FileUtils.rm_r tmp_dir}

      it 'should create threads from procs' do
        subject

        3.times do |n|
          path = "#{tmp_dir}/#{n}.txt"
          expect File.exists?(path)
          expect(File.read(path)).to eq n.to_s
        end
      end
    end
  end
end
