def get_statistics(s)
  a=[0,0,0,0]
  an=/[a-zA-Z0-9]/
  ws=/[ \t\n]/
  s.each_byte{|x|
    s=x.chr
    a[an=~s ?2:ws=~s ?1: x<127&&x>32?3:0]+=1
  }
  a[1..-1] * '/'
end

class Squeezer
  def sharp
    @src.gsub!(/^#(?!!).*/, '')
    @src.gsub!(/ *# .*/, '')
  end

  def c99
    @src.gsub!(/ *\/\/.*/, '')
    @src.gsub!(/\/\*.*?\*\//m, '')
  end

  def d
    c99
    # cannot nest, incorrect
    @src.gsub!(/\/\+.*?\+\//, '')
  end

  def hs
    @src.gsub!(/ *--.*/, '')
  end

  def caml
    @src.gsub!(/\(\*.*?\*\)/m, '')
  end

  def blank
    @src.gsub!(/^\n/, '')
  end

  def last_ws
    @src.rstrip!
  end

  def trailing_ws
    @src.gsub!(/ +$/, '')
  end

  def leading_ws
    @src.gsub!(/^ +/, '')
  end

  def any_ret(t)
    @src.gsub!("#{t}\n", t)
  end

  def ret_any(t)
    @src.gsub!("\n#{t}", t)
  end

  def semi_ret
    any_ret(';')
  end

  def cond_ret
    # long_exp?true_exp:false_exp
    any_ret('?')
    any_ret(':')
    any_ret('&&')
    any_ret('||')
  end

  def bra_ret
    any_ret('{')
  end

  def cket_ret
    any_ret('}')
  end

  def ret_cket
    ret_any('}')
  end

  def bracket_ret
    bra_ret
    ret_cket
  end

  def initialize(filename)
    @ext = File.extname(filename)
    @base = File.basename(filename, @ext)
    @src = File.read(filename)
    @orig_size = @src.size
  end

  def run
    [SRC_DIR, GOLF_DIR].each do |dir|
      squeezer = File.join(dir, 'squeezer', "#{@ext[1..-1]}.rb")
      if File.exist?(squeezer)
        eval(File.read(squeezer))
      end
    end

    now = Time.now.strftime('-%Y-%m-%d-%H-%M-%S')
    squeezed = File.join(CODE_DIR, @base+now+@ext)
    File.open(squeezed, 'w') do |ofile|
      ofile.print(@src)
    end

    puts "#{@orig_size} => #{@src.size} (#{get_statistics(@src)})"
    if @ext == '.z8b'
      system("z80dasm -a -t -g0 #{squeezed} 2>-")
    elsif @ext != '.out'
      system("objdump -b binary -m i386 #{squeezed} 2>-")
    else
      puts @src
    end
    puts

    [squeezed, @src.size]
  end
end

def squeeze(filename)
  print 'Running squeezer... '
  sq = Squeezer.new(filename)
  sq.run
end
