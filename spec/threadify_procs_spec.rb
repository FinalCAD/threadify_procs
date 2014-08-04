require 'spec_helper'
require 'fileutils'

class ThreadifiedJob
  include ThreadifyProcs
  attr_reader :total

  def initialize
    @total = 0
  end

  def procs
    [].tap do |_procs|
      3.times do |n|
        _procs << Proc.new do
          @total += n+1
        end
      end
    end
  end

  def launch
    call_with_threads procs, number_of_threads: 2
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
    subject{ ThreadifiedJob.new }

    it 'should create threads from procs' do
      subject.launch
      expect(subject.total).to eq 6
    end

    describe 'with_writer' do
      subject{ ThreadifiedJobWithWriter.new }
      before { FileUtils.mkdir tmp_dir}
      after { FileUtils.rm_r tmp_dir}

      it 'should create threads from procs' do
        subject.launch

        3.times do |n|
          path = "#{tmp_dir}/#{n}.txt"
          expect File.exists?(path)
          expect(File.read(path)).to eq n.to_s
        end
      end
    end
  end
end
