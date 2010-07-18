@src.gsub!(/^#.*/,'')
@src.gsub!(/^(.*?:.*?)\s#.*/,'\1')
blank
trailing_ws
last_ws
