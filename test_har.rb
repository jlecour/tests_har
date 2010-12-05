require 'rubygems'
require 'time'
require 'yajl'
require 'rest-client'
require 'g'
require 'ap'

def build_log(entries)
  {
    :version => "1.1",
    :creator => {
      :name => "Qualitics",
      :version => "0.0.1"
    },
    :browser => {
      :name => "",
      :version => ""
    },
    :pages => build_pages(entries),
    :entries => entries
  }
end

def build_request(request)
  {
    :method => "GET",
    :url => request.url,
    :httpVersion => 'HTTP/1.1',
    :cookies => build_cookies(request.cookies),
    :headers => build_headers(request.headers),
    :headersSize => "?",
    :bodySize => -1
  }
end

def build_pages(entries)
  entries.inject([]) do |pages, entry|
    pages << {
      :startedDateTime => entry[:startedDateTime],
      :id => entry[:pageref],
      :title => "?",
      :pageTimings => {
        :onContentLoad => '?',
        :onLoad => '?'
      }
    }
  end
end

# TODO : formatter les headers correctement
# et ne garder que ceux qui sont utiles
def build_headers(headers)
  headers.select do |key, value|
    !(key.to_s =~ /cookie/i)
  end.inject([]) do |memo, header|
    memo << {
      :name => header[0].to_s.split('_').map(&:capitalize).join('-'),
      :value => header[1].to_s
    }
  end
end

def build_cookies(headers)
  []
end

def build_response(response)
  {
    :status => response.code,
    :statusText => status_text(response.code),
    :httpVersion => http_version(response),
    :cookies => build_cookies(response.cookies),
    :headers => build_headers(response.headers),
    :content => build_content(response),
    :redirectURL => redirection(response.headers),
    :headersSize => "?",
    :bodySize => "?"
  }
end

def build_content(response)
  {
    :size => response.headers[:content_length].to_i,
    :mimeType => MIME::Types[response.headers[:content_type]].first.to_s,
    :text => response.body,
  }
end

def build_timings()
  {
    :dns => 0,
    :connect => 0,
    :blocked => 0,
    :send => 0,
    :wait => 0,
    :receive => 0
  }
end

def build_cache
  {}
end

def build_entries(start_url, headers = {})
  request, response, result = RestClient.get(start_url, headers) do |response, request, result, &block|
    [request, response, result]
  end
  [{
    :pageref => "page_1",
    :startedDateTime => Time.now.iso8601,
    :cookies => build_cookies(response.headers),
    :request => build_request(request),
    :response => build_response(response),
    :cache => build_cache,
    :timings => build_timings,
  }]
end

def http_version(response)
  version = response.net_http_res.http_version
  "HTTP/#{version}"
end

def status_text(code)
  RestClient::STATUSES[code]
end

def redirection(headers)
  headers[:location]
end

url = 'http://www.google.com'
headers = {
  :accept => 'text/html'
}

entries = build_entries(url,headers)

log = {
  :log => build_log(entries)
}

puts Yajl::Encoder.encode(log)
# ap response.net_http_res.to_hash