require "benchmark"

def yepnope(r); puts r ? "Success!" : "Failure!"; end

test_urls = {
  'flickr-photostream' => 'http://localhost:6969/flickr-photostream.rss',
  'flickr-user-photostream' => 'http://localhost:6969/flickr-user/sidesh0w/feed.rss',
  'tumblr-dashboard' => 'http://localhost:6969/tumblr-dashboard.rss',
  'tumblr-likes' => 'http://localhost:6969/tumblr-likes.rss',
  'tumblr-user' => 'http://localhost:6969/tumblr-user/liartownusa/feed.rss',
}

task :test do
  l = test_urls.keys.map(&:length).max + 12

  Benchmark.bm(l) do |x|
    test_urls.each do |route, url|
      x.report("Testing #{route}...") {
        yepnope system("curl -s #{url} > /dev/null")
      }
    end
  end
end
