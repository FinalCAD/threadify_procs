# ThreadifyProcs

[![Build Status](https://travis-ci.org/aq/threadify_procs.svg?branch=master)](https://travis-ci.org/aq/threadify_procs)

Create an array of Procs, launch them within threads. It adresses the common
problem of writting files concurrently in threads with a ruby proces or
downloading simultaneously multiple files. It avoids 'Too many open files'
errors.

## Usage

    require 'threadify_procs'
    procs = [
      Proc.new { puts 1 },
      Proc.new { puts 2 }
    ]
    call_with_threads procs, number_of_threads: 50

An other option is available :with_writer (boolean). Its goal is to launch
another thread which responsibility is to create files on disc.

    require 'threadify_procs'
    procs = []
    10_000.times do |n|
      Proc.new do
        @files_to_write << [
          "#{Rails.root}/tmp/#{n}.txt", SecureRandom.uuid]
      end
    end
    launch_in_threads procs, number_of_threads: 50, with_writer: true
