def edit_distance(a, b)
  a = a.downcase
  b = b.downcase
  d = Array.new(b.size+1){Array.new(a.size+1){0}}
  0.upto(a.size){|i|d[0][i]=i}
  0.upto(b.size){|i|d[i][0]=i}
  a.size.times do |i1|
    b.size.times do |i2|
      cost = a[i1] == b[i2] ? 0 : 1
      d[i2+1][i1+1] = [d[i2+1][i1]+1, d[i2][i1+1]+1, d[i2][i1]+cost].min
    end
  end
  d[-1][-1]
end

def similarity(a, b)
  s = edit_distance(a, b)
  s = s * 10000 / a.size
  if a =~ /#{b}/i
    s /= a =~ /^#{b}/i ? 3 : 2
  end
  s
end
