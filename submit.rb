def confirm_submit(code_size, user)
  if $submit_confirm
    print "Submit this #{code_size}B code as #{user} (Y/n) ? : "
    yn = STDIN.gets
    if yn !~ /^$/ && yn !~ /^[yY]$/
      exit 0
    end
  end
end

def submit_ag(base, user_suffix, num_retry, code, ext, pn, code_size)
  user = get_user
  if user_suffix
    user = "#{user}(#{user_suffix})"
  end

  confirm_submit(code_size, user)

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

def submit_ag_perf(filename, input_filename)
  ext = File.extname(filename)
  base = File.basename(filename, ext)

  Net::HTTP.start('golf.shinh.org', 80) do |http|
    req = Net::HTTP::Post.new('/checker.rb')
    FileUtils.cp(filename, tmpfile = File.join('/tmp', base+ext))
    input = input_filename ? File.read(input_filename) : ""
    req.set_multipart_form_data({'file' => tmpfile}, {'input' => input})
    File.unlink(tmpfile)

    res = http.request(req)
    if res.class.superclass != Net::HTTPSuccess
      puts "Failed to connect the golf server"
      exit 1
    end

    res = res.read_body
    puts res
  end
end

SPOJ_LANGS = {
  '.adb' => 7,
  '.s' => 13,
  '.sh' => 28,
  '.bf' => 12,
  # <option value="11" >C (gcc 4.3.2)</option>
  # <option value="34" >C99 strict (gcc 4.3.2)</option>
  '.c' => 11,
  '.cs' => 27,
  # <option value="1" >C++ (g++ 4.0.0-8)</option>
  # <option value="41" >C++ (g++ 4.3.2)</option>
  '.cc' => 41,
  # <option value="14" >Clips (clips 6.24)</option>
  '.clj' => 111,
  # <option value="32" >Common Lisp (clisp 2.44.1)</option>
  # <option value="31" >Common Lisp (sbcl 1.0.18)</option>
  '.l' => 31,
  '.d' => 20,
  '.erl' => 36,
  '.fs' => 124,
  '.f95' => 5,
  '.go' => 114,
  '.hs' => 21,
  # <option value="16" >Icon (iconc 9.4.3)</option>
  # <option value="9" >Intercal (ick 0.28-4)</option>
  '.jar' => 24,
  '.java' => 10,
  '.js' => 35,
  '.lua' => 26,
  '.n' => 30,
  # <option value="25" >Nice (nicec 0.9.6)</option>
  '.ml' => 8,
  # <option value="2" >Pascal (gpc 20070904)</option>
  # <option value="22" >Pascal (fpc 2.2.4)</option>
  '.pas' => 2,
  '.pl' => 3,
  '.pl6' => 54,
  '.php' => 29,
  '.pike' => 19,
  '.pro' => 15,
  # <option value="4" >Python (python 2.5)</option>
  # <option value="116" >Python 3 (python 3.1.2)</option>
  '.py' => 4,
  '.rb' => 17,
  '.rb19' => 17,
  '.scala' => 39,
  # <option value="18" >Scheme (stalin 0.11)</option>
  # <option value="33" >Scheme (guile 1.8.5)</option>
  '.scm' => 33,
  '.st' => 23,
  '.tcl' => 38,
  '.ws' => 6,
}

def submit_spoj(code_file, code_size, base, ext)
  user = get_user

  langid = SPOJ_LANGS[ext]
  if !langid
    puts "Cannot determine the language for #{ext}"
    exit 1
  end

  confirm_submit(code_size, user)

  print 'Submitting... '

  require 'net/https'

  probname = base.upcase

  pass = $spoj_pass
  if !pass
    print "Password for #{user}: "
    system("stty -echo")
    pass = gets.strip
    system("stty echo")
  end

  code = File.read(code_file)

  https = Net::HTTP.new('www.spoj.pl', 443)
  https.use_ssl = true
  https.start do |w|
    body = ("submit=Send&login_user=#{user}&password=#{pass}&lang=#{langid}&" +
            "problemcode=#{probname}&file=#{URI.escape(code, /[^\w]/)}")
    r = w.post("/SHORTEN/submit/complete/", body)
    if r.code == '200' && r.body =~ /Solution submitted/
      puts 'done!'
      puts 'https://www.spoj.pl/SHORTEN/status/'
    else
      puts "failed! (#{r.code})"
      File.open('error.html', 'w') do |of|
        of.print r.body
      end
      puts "error.html was saved"
      exit 1
    end
  end
end
