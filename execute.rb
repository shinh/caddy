require 'open3'

require 'db'

def show_error_none(expect, output)
  puts "\nOutput:\n#{output}\n\nExpect:\n#{expect}\n\n"
end

def show_error_diff(expect, output)
  File.open('output', 'w') do |ofile|
    ofile.puts(output)
  end
  File.open('expect', 'w') do |ofile|
    ofile.puts(expect)
  end
  system("diff -u expect output")
end

def show_error(expect, output)
  output.gsub!("\n", "\\n\n")
  expect.gsub!(/\n/, "\\n\n")
  if $diff_style == :diff
    show_error_diff(expect, output)
  elsif $diff_style == :all
    show_error_none(expect, output)
    puts 'Diff:'
    show_error_diff(expect, output)
  else
    show_error_none(expect, output)
  end
end

def execute(type, filename, testcases)
  ext = File.extname(filename)[1..-1]
  FileUtils.rm_rf(TEST_DIR)
  FileUtils.mkdir_p(TEST_DIR)
  testfile = File.join(TEST_DIR, 'test.' + ext)
  File.open(testfile, 'w') do |ofile|
    ofile.print(File.read(filename))
  end

  failed = false
  Dir.chdir(TEST_DIR) do
    if (File.exist?(compiler = File.join(GOLF_DIR, 'executors', "_#{ext}")) ||
        File.exist?(compiler = File.join(SRC_DIR, 'executors', "_#{ext}")))
      print 'Compiling... '
      cmd = "#{compiler} '#{testfile}' '#{filename}'"
      if $suppress_stderr
        cmd += ' 2>-'
      end
      if system(cmd)
        puts 'OK'
      else
        puts 'FAILED'
        return false
      end
    end

    if (!File.exist?(executor = File.join(GOLF_DIR, 'executors', ext)) &&
        !File.exist?(executor = File.join(SRC_DIR, 'executors', ext)))
      raise "No executor found for #{filename}"
    end

    n = 0
    testcases.each do |i, e|
      i.gsub!("\r\n", "\n")
      e.gsub!("\r\n", "\n")
      print "Test ##{n+=1}... "
      cmd = "#{executor} '#{testfile}' '#{filename}'"
      if $suppress_stderr
        cmd += ' 2>-'
      end
      start = Time.now
      IO.popen(cmd, 'r+') do |pipe|
        if ext == 'sed' && i.empty?
          i = "\n"
        end
        begin
          pipe.write(i)
        rescue Errno::EPIPE
        end
        pipe.close_write
        o = pipe.read
        case type
        when :ag
          e.rstrip!
          o.rstrip!
        when :cg
          e.strip!
          o.strip!
        end
        o.gsub!("\r\n", "\n")

        if o == e
          puts "OK #{Time.now-start}"
        else
          puts 'FAILED'
          failed = true
          show_error(e, o)
        end
      end
    end
  end
  puts
  !failed
end
