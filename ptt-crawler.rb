# encoding: utf-8
require 'open-uri'
require 'openssl'
require 'date'
require 'cgi'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
STDERR.reopen('crawler-log')
def output *a
  STDERR.puts(*a)
  puts(*a)
end

def read_list url, date
  output("check #{url}")
  h = url.scan(/\w+:\/\/[^\/]+/)[0]
  s = open(url, 'Cookie' => 'over18=1'){|f| f.read}
  ary = s.scan(/<a href="(\/bbs\/Gossiping.+?)">(.+?)<\/a>/)
    .zip(s.scan(/<div class="date">(.+?)<\/div>/))
    .map{|a| a.flatten}
    .select{|u, t, d|
      d =~ /(\d+)\/(\d+)/
      $1.to_i == date.month && $2.to_i == date.mday
    }
  pre_url = h+s.scan(/<a class=".+?" href="(.+?)">.*?上頁.*?<\/a>/)[0][0]
  [ary, pre_url]
end
def read_page title, url, date
  cont = CGI.unescape_html(
    open(url, 'Cookie' => 'over18=1'){|f| f.read}
      .scan(/<div id="main-content" class="bbs-screen bbs-content">(.+?)<span class="f2">※ 發信站: 批踢踢實業坊/m)[0][0]
      .gsub(/<\/?\w+(?:\s*\w+=".+?")*\s*\/?>/, "\n")
      .gsub(/\n\n+/, "\n")
  )
  dir = 'ptt-articles-%d-%02d-%02d' % [date.year, date.month, date.mday]
  File.directory?(dir) || Dir.mkdir(dir)
  fname = "#{dir}/#{title.gsub(/[:\\\/?]/, '')}"
  File.open(fname, 'w:utf-8'){|f| f.puts(cont)}
end

def ptt_crawler m, d
  first = true
  host = 'https://www.ptt.cc'
  url = 'https://www.ptt.cc/bbs/Gossiping/index.html'
  output("ptt crawler start (#{m}, #{d})")
  output(Time.now)
  while true
    date = Date.new(Date.today.year, m, d)
    ary, pre_url = read_list(url, date)
    if ary.size == 0 && first
      url = pre_url
    elsif ary.size > 0
      first = nil
      url = pre_url
      ary.map{|u, t, d_|
        title = CGI.unescape_html(t)
        output("download #{title} (#{m}/#{d})")
        begin
          read_page(title, "#{host}#{u}", date)
        rescue
          output('---- failed ----', $!, '-'*16)
        end
      }
    else
      break
    end
  end
end

if ARGV[0]
  ptt_crawler(ARGV[0].to_i, ARGV[1].to_i)
else
  puts('input date: (like 1/1)')
  ptt_crawler(*STDIN.gets.split(/\//).map(&:to_i))
end
