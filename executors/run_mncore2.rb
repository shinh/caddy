#!/usr/bin/env ruby

mncore2_emuenv_url = "https://projects.preferred.jp/mn-core/assets/mncore2_emuenv_20240221.zip"
mncore2_emuenv = "/tmp/mncore2_emuenv_20240221"
if !File.exist?(mncore2_emuenv)
  Dir.chdir("/tmp") do
    STDERR.puts "Downloading mncore2_emuenv in #{mncore2_emuenv}..."
    system("curl -O #{mncore2_emuenv_url}")
    system("unzip mncore2_emuenv_20240221.zip")
  end
end

ASM = "#{mncore2_emuenv}/assemble3"
EMU = "#{mncore2_emuenv}/gpfn3_package_main"

def write_pdm(str)
  if str.empty?
    return ""
  end

  payload = ""
  str.each_byte do |b|
    payload += "%02x" % b
  end
  while payload.size % 16 != 0
    payload += "00"
  end
  addr = "%09x" % 0
  len = "%06x" % (payload.size / 16)

  vsm = "c 0 0 i01 i00 0 #{addr} #{len} #{payload}\n"
  vsm += "nop; wait i01\n"
  return vsm
end

def parse_pdm_out(out)
  o = ""
  out.each_line do |line|
    o += line.split(": ")[1].strip
  end

  s = ""
  (o.size / 2).times do |i|
    c = o[i*2, 2].hex
    break if c == 0
    s += c.chr
  end
  s
end

full_vsm = write_pdm(STDIN.read)
full_vsm += File.read(ARGV[0])
full_vsm += "f\n"
full_vsm += "e 0 0 i02 i00 0 000000000 010000\n"
full_vsm += "nop; wait i02\n"

File.open("/tmp/full.vsm", "w") do |of|
  of.print(full_vsm)
end

score = `#{ASM} --instruction-mode flat #{ARGV[0]}`.split("\n").size
STDERR.puts "#{score} instructions"

system("#{ASM} --instruction-mode flat /tmp/full.vsm > /tmp/full.asm")
system("#{EMU} < /tmp/full.asm > /tmp/emu.out")

print parse_pdm_out(File.read("/tmp/emu.out"))
