# encoding: utf-8
require 'open-uri'
require 'openssl'
require 'date'
require 'cgi'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
# STDOUT.reopen('crawler-log-%s' % Time.now.strftime('%Y-%m-%d-%H-%M-%S'))
# def output *a
  # STDERR.puts(*a)
  # puts(*a)
# end

def read_index_page url
  puts("read_index_page(#{url})")
  text = open(url, 'Cookie' => 'over18=1'){|f| f.read}
  {
    articles: text
      .scan(/<div\sclass="title">.+?
            <a\shref="(.+?)">(.+?)<\/a>.+?
            <\/div>.+?
            <div\sclass="meta">.+?
            <div\sclass="date">(.+?)<\/div>.+?
            <div\sclass="author">(.+?)<\/div>.+?<\/div>/xm)
      .map{|url, title, date, author|
        month, day = date.split(/\//).map(&:to_i)
        puts title, url, ''
        nil
      },
    pre_index_url:
      url =~ /index(\d+)/ ?
      url.sub(/index\d+/, "index#{$1.to_i-1}") :
      "https://www.ptt.cc#{text.scan(/<a class=".+?" href="(.+?)">.*?上頁.*?<\/a>/)[0][0]}"
  }
end

def read_page url
  # cont = CGI.unescape_html(
    # open(url, 'Cookie' => 'over18=1'){|f| f.read}
      # .scan(/<div id="main-content" class="bbs-screen bbs-content">(.+?)<span class="f2">※ 發信站: 批踢踢實業坊/m)[0][0]
      # .gsub(/<\/?\w+(?:\s*\w+=".+?")*\s*\/?>/, "\n")
      # .gsub(/\n\n+/, "\n")
  # )
  # dir = 'ptt-articles-%d-%02d-%02d' % [date.year, date.month, date.mday]
  # File.directory?(dir) || Dir.mkdir(dir)
  # fname = "#{dir}/#{title.gsub(/[:\\\/?]/, '')}"
  # File.open(fname, 'w:utf-8'){|f| f.puts(cont)}
end

def ptt_crawler m, d
  # first = true
  # host = 'https://www.ptt.cc'
  # url = 'https://www.ptt.cc/bbs/Gossiping/index.html'
  # output("ptt crawler start (#{m}, #{d})")
  # output(Time.now)
  # while true
    # date = Date.new(Date.today.year, m, d)
    # ary, pre_url = read_list(url, date)
    # if ary.size == 0 && first
      # url = pre_url
    # elsif ary.size > 0
      # first = nil
      # url = pre_url
      # ary.map{|u, t, d_|
        # title = CGI.unescape_html(t)
        # output("download #{title} (#{m}/#{d})")
        # begin
          # read_page(title, "#{host}#{u}", date)
        # rescue
          # output('---- failed ----', $!, '-'*16)
        # end
      # }
    # else
      # break
    # end
  # end
end

if ARGV[0]
  ptt_crawler(ARGV[0].to_i, ARGV[1].to_i)
else
  puts('input date: (like 1/1)')
  ptt_crawler(*STDIN.gets.split(/\//).map(&:to_i))
end
