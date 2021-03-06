# -*- coding: utf-8 -*-

require 'test_helper'

class SetEnvCommandTest < Test::Unit::TestCase
  def setup
    $conf = Msh::Conf.new.merge!(
                 {
                   :proxy_addr        => "proxy.example.jp",
                   :proxy_port        => "8080",
                   :domain            => "server.example.jp",
                   :path              => "/public-api/v1",
                   :access_key        => "xxxxxxxxxxxxxx",
                   :access_key_secret => "yyyyyyyyyyyyyyyyy",
                   :user_code         => "tsa99999999",
                 }
                 )
  end

  def test_no_option
    $output = Msh::Output::Buffer.new

    response_conf = Msh::Conf.new.merge!(
                 {
                   :proxy_addr        => "proxy.example.jp",
                   :proxy_port        => "8080",
                   :domain            => "server.example.jp",
                   :path              => "/public-api/v1",
                   :access_key        => "xxxxxxxxxxxxxx",
                   :access_key_secret => "yyyyyyyyyyyyyyyyy",
                   :user_code         => "tsa00000000",
                 }
                 )

    c = Msh::Command::SetEnvCommand.new
    c.expects(:env_set).returns(response_conf)

    c.doit(["env", "set", "user_code", "tsa00000000"])

    assert_kind_of(String, $output.buffer)
    assert_equal("tsa00000000", $conf[:user_code])
    assert(! $output.buffer.nil?)
    assert(! $output.buffer.empty?)
  end

end
