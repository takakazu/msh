# -*- coding: utf-8 -*-

require 'test_helper'

class UnsetSaGroupCommandTest < Test::Unit::TestCase
  def setup
    $conf = {
      :proxy_addr        => "proxy.example.jp",
      :proxy_port        => "8080",
      :domain            => "server.example.jp",
      :path              => "/public-api/v1",
      :access_key        => "xxxxxxxxxxxxxx",
      :access_key_secret => "yyyyyyyyyyyyyyyyy",
      :user_code         => "tsa99999999",
    }
  end

  def test_no_option
    $output = Msh::Output::Buffer.new

    response_json = {
      "sa" => [],
      "id"   => 3,
      "name" => "SA Group"
    }.to_json

    response = mock()
    response.stubs(:code).returns("200")
    response.stubs(:content_type).returns("application/json")
    response.stubs(:body).returns(response_json)

    c = Msh::Command::UnsetSaGroupCommand.new
    c.expects(:execute).returns(response)

    c.doit(["unset", "sagroup", "3", "name", "sa"])

expected_str = <<EOS
---
SaGroup ID: 3
SaGroup Name: SA Group
SA:
EOS

    assert_equal(expected_str, $output.buffer)

    assert_kind_of(String, $output.buffer)
    assert(! $output.buffer.nil?)
    assert(! $output.buffer.empty?)
  end

end
