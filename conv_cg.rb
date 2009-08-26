require 'cases'
Dir["sample/*.test"].each do |f|
  x=File.basename(f,".test")
  n = 0
  get_onefile_cases(File.dirname(f)+"/"+x)[1].each do |i,o|
    n+=1
    if !i.empty?
      open("cg/#{x}#{n}.input", 'w') do |of|
        of.puts(i)
      end
    end
    open("cg/#{x}#{n}.output", 'w') do |of|
      of.puts(o)
    end
  end
end
