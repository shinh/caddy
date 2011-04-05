def submit_ag(base, user_suffix, num_retry, code, ext, pn)
  user = get_user
  if user_suffix
    user = "#{user}(#{user_suffix})"
  end

  if $submit_confirm
    print "Submit this #{code_size}B code as #{user} (Y/n) ? : "
    yn = STDIN.gets
    if yn !~ /^$/ && yn !~ /^[yY]$/
      exit 0
    end
  end

  print 'Submitting... '
  data = {
    'problem' => pn,
    'user' => user,
    'reveal' => $open_code_statistics ? '1' : '',
  }

  ok = false
  1.upto(num_retry) do |num_attacks|
    Net::HTTP.start('golf.shinh.org', 80) do |http|
      req = Net::HTTP::Post.new('/submit.rb')
      FileUtils.cp(code, tmpfile = File.join('/tmp', base+ext))
      req.set_multipart_form_data({'file' => tmpfile}, data)
      File.unlink(tmpfile)
      res = http.request(req)
      if res.class.superclass != Net::HTTPSuccess
        puts "Failed to connect the golf server"
        exit 1
      end

      res = res.read_body
      if res =~ /Success[^<]*/
        puts $&
        ok = true
      else
        puts 'FAILED'
        puts
        puts res.sub(/.*<body>/m, '').gsub(/<.*?>/, '').sub('return top', '')
      end
    end

    if ok
      break
    end

    if num_attacks % 100 == 0
      puts "#{num_attacks}..."

      if num_attacks >= 10000
        raise 'Please refrain from >10000 attempts'
      end
    end
  end
end
