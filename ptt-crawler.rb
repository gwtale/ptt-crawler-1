# encoding: utf-8
require 'open-uri'
require 'openssl'
require 'date'
require 'cgi'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def read_index_page url
  puts("read_index_page(#{url})")
  text = open(url, 'Cookie' => 'over18=1'){|f| f.read}
  if url == 'https://www.ptt.cc/bbs/Gossiping/index.html'
    text = text
      .split(/\n/)
      .take_while{|s| s !~ /class="r-list-sep"/}
      .join
  end
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
        {url: url, date: Date.new(Date.today.year, month, day)}
      },
    pre_index_url:
      url =~ /index(\d+)/ ?
      url.sub(/index\d+/, "index#{$1.to_i-1}") :
      "https://www.ptt.cc#{text.scan(/<a class="btn wide" href="(\/bbs\/Gossiping\/index\d+.html)">&lsaquo; 上頁<\/a>/)[0][0]}"
  }
end

def read_page url
  puts("read_page(#{url})")
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

def ptt_crawler opts
  host = 'https://www.ptt.cc'
  if opts[:index]
    opts[:index].map do |i|
      h = read_index_page("https://www.ptt.cc/bbs/Gossiping/index#{i}.html")
      h[:articles].map do |h_|
        read_page(h_[:url])
      end
    end
  elsif opts[:date]
    loop = true
    url = 'https://www.ptt.cc/bbs/Gossiping/index.html'
    while loop
      h = read_index_page(url)
      h[:articles].reverse.map do |h_|
        if h_[:date] == opts[:date]
          read_page(h_[:url])
        elsif h_[:date] < opts[:date]
          p 'noooo'
          loop = false
          break
        end
      end
      url = h[:pre_index_url]
    end
  end
end

case ARGV[0]
when /date=(\d+)\/(\d+)/
  ptt_crawler(date: Date.new(Date.today.year, $1.to_i, $2.to_i))
when /date=(-?\d+)/
  ptt_crawler(date: Date.today-$1.to_i)
when /index=(\d+)-(\d+)/
  a = [$1.to_i, $2.to_i]
  ptt_crawler(index: ((a.min)..(a.max)).to_a.reverse)
when /index=(\d+)/ 
  ptt_crawler(index: [$1.to_i])
else
  puts 'not recognized parameter.'
end
