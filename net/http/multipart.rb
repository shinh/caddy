#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# = net/http/multipart.rb
#
# Copyright (c) 2007 Hirofumi HONDA
#
# This program is free software. You can re-distribute and/or
# modify this program under the same terms of ruby itself ---
# Ruby Distribution License or GNU General Public License.
#

require 'net/http'
begin
  require 'rubygems'
  require 'mime/types'
rescue LoadError => e
end

module Net
  module HTTPHeader

    CR  = "\015"
    LF  = "\012"
    EOL = CR + LF

    def set_multipart_form_data( filepath = {}, params = {} )

      boundary = "boundary"
      self.set_content_type 'multipart/form-data', { "boundary" => boundary }
      content = ""

      params.each do |key, value|
        value = [value] if value.class != Array
        value.each do |i|
          content << [
            %Q|--#{boundary}|,
            %Q|Content-Disposition: form-data; name="#{key}"|,
            %Q||,
            %Q|#{i}|
          ].join(EOL) << EOL
        end
      end

      filepath.each do |key, value|
        value = [value] if value.class != Array
        value.each do |i|
          begin
            mime_type = MIME::Types.of(i).to_s
          rescue NameError => e
          ensure
            mime_type = "application/octet-stream" if (mime_type.nil? or mime_type.empty?)
          end
          content << [
            %Q|--#{boundary}|,
            %Q|Content-Disposition: form-data; name="#{key}"; filename="#{File::basename(i)}"|,
            %Q|Content-Type: #{mime_type}|,
            %Q||,
            %Q|#{open(i).read}|
          ].join(EOL) << EOL
        end
      end

      content << %Q|--#{boundary}--|

      self.content_length = content.size
      self.body = content

    end
  end
end

if __FILE__==$0

  Net::HTTP.version_1_2
  http = Net::HTTP.start("localhost", 12380 )
  req = Net::HTTP::Post.new("/attach.cgi")
  req.set_multipart_form_data({"attach_file" => ARGV[0]}, {"p" => "FrontPage", "command" => "edit", "attach" => "ファイルの添付"})
  res = http.request(req)

  if res.class.superclass == Net::HTTPSuccess
    puts "OK"
  else
    puts "failed"
  end

end
