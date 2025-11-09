# frozen_string_literal: false
require 'test/unit'
require 'uri/http'
require 'uri/https'

class URI::TestHTTP < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def uri_to_ary(uri)
    uri.class.component.collect {|c| uri.send(c)}
  end

  def test_build
    u = URI::HTTP.build(host: 'www.example.com', path: '/foo/bar')
    assert_kind_of(URI::HTTP, u)
  end

  def test_build_empty_host
    assert_raise(URI::InvalidComponentError) { URI::HTTP.build(host: '') }
  end

  def test_parse
    u = URI.parse('http://a')
    assert_kind_of(URI::HTTP, u)
    assert_equal([
      'http',
      nil, 'a', URI::HTTP.default_port,
      '', nil, nil
    ], uri_to_ary(u))
  end

  def test_normalize
    host = 'aBcD'
    u1 = URI.parse('http://' + host + '/eFg?HiJ')
    u2 = URI.parse('http://' + host.downcase + '/eFg?HiJ')
    assert_equal('abcd', u1.normalize.host)
    assert_equal(u1.path, u1.normalize.path)
    assert_equal(u2.normalize, u1.normalize)
    refute_same(u1.host, u1.normalize.host)
    assert_same(u2.host, u2.normalize.host)

    assert_equal('http://abc/', URI.parse('http://abc').normalize.to_s)
  end

  def test_equal
    assert_equal(URI.parse('http://ABC'), URI.parse('http://abc'))
    assert_equal(URI.parse('http://ABC/def'), URI.parse('http://abc/def'))
    refute_equal(URI.parse('http://ABC/DEF'), URI.parse('http://abc/def'))
  end

  def test_request_uri
    assert_equal('/', URI.parse('http://a.b.c/').request_uri)
    assert_equal('/?abc=def', URI.parse('http://a.b.c/?abc=def').request_uri)
    assert_equal('/', URI.parse('http://a.b.c').request_uri)
    assert_equal('/?abc=def', URI.parse('http://a.b.c?abc=def').request_uri)
    assert_equal(nil, URI.parse('http:foo').request_uri)
  end

  def test_select
    assert_equal(['http', 'a.b.c', 80], URI.parse('http://a.b.c/').select(:scheme, :host, :port))
    u = URI.parse('http://a.b.c/')
    assert_equal(uri_to_ary(u), u.select(*u.component))
    assert_raise(ArgumentError) do
      u.select(:scheme, :host, :not_exist, :port)
    end
  end

  def test_authority
    assert_equal('a.b.c', URI.parse('http://a.b.c/').authority)
    assert_equal('a.b.c:8081', URI.parse('http://a.b.c:8081/').authority)
    assert_equal('a.b.c', URI.parse('http://a.b.c:80/').authority)
  end


  def test_origin
    assert_equal('http://a.b.c', URI.parse('http://a.b.c/').origin)
    assert_equal('http://a.b.c:8081', URI.parse('http://a.b.c:8081/').origin)
    assert_equal('http://a.b.c', URI.parse('http://a.b.c:80/').origin)
    assert_equal('https://a.b.c', URI.parse('https://a.b.c/').origin)
  end

  def test_deconstruct_keys
    uri = URI("http://example.com:8080/path?foo=bar")
    keys = uri.deconstruct_keys(nil)
    assert_equal "http", keys[:scheme]
    assert_equal "example.com", keys[:host]
    assert_equal 8080, keys[:port]
    assert_equal "/path?foo=bar", keys[:request_uri]
    assert_equal "example.com:8080", keys[:authority]
    assert_equal "http://example.com:8080", keys[:origin]
  end

  def test_pattern_matching_origin
    begin
      uri = URI("http://api.example.com/v2/users")
      result = instance_eval <<~RUBY, __FILE__, __LINE__ + 1
        case uri
        in origin: "http://api.example.com", path: /^\\/v2/
          "api v2"
        else
          "no match"
        end
      RUBY
      assert_equal "api v2", result
    rescue SyntaxError
      omit "Pattern matching not supported in Ruby < 2.7"
    end
  end

  def test_pattern_matching_authority
    begin
      uri = URI("http://example.com:8080/path")
      result = instance_eval <<~RUBY, __FILE__, __LINE__ + 1
        case uri
        in authority: "example.com:8080", scheme: "http"
          "matched"
        else
          "no match"
        end
      RUBY
      assert_equal "matched", result
    rescue SyntaxError
      omit "Pattern matching not supported in Ruby < 2.7"
    end
  end
end
