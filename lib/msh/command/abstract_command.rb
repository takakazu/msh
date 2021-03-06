# -*- coding: utf-8 -*-

require 'msh/constants'
require 'msh/command'
require 'msh/api'

module Msh

  # template method
  class AbstractCommand
    include Msh::Constants

    def initialize
      @request = {
        :api    => nil,
        :method => nil,
      }
    end

    private

    def check_http_success(response)
      unless response.code =~ HTTP_SUCCESS
        $output.puts "API response status code is #{response.code} (#{response.message})."
        return false
      end
      return true
    end

    def check_request_response(response)
      case response.content_type
      when 'application/json'
        response_body_json = json_load(response.body)
        return %(successed failed).include?(response_body_json['status'])
      when 'text/plain'
        return response.code =~ HTTP_SUCCESS
      when 'application/octet-stream'
        return (response.code =~ HTTP_OK) || (response.code =~ HTTP_CREATED) || (response.code =~ HTTP_NO_CONTENT)
      else
        return response.code =~ HTTP_SUCCESS
      end
    end

    def puts_response(response)
      case response.content_type
      when 'application/json'
        response_body_json = json_load(response.body)
        $output.puts YAML.dump(response_body_json)
      when 'text/plain'
        if response.code =~ HTTP_NO_CONTENT
          $output.puts 'Success.'
        else
          $output.puts response.body
        end
      when 'text/csv'
        $output.puts response.body
      when ''
        return
      else
#        $output.puts "Failure."
      end
    end

    def json_load(obj)
      return JSON.load(obj)
    end

    def module_init(command_args)
      api = Msh::Api::PUTUserUserCodeSaSaCodeConfigWorkingBlank.new({
                                                                      :user_code => $conf[:user_code],
                                                                      :sa => command_args[:sa]
                                                                    })
      execute(api)
    end

    def get_vendor_code_sa_type(command_args)
      api = Msh::Api::GETUserUserCodeSaSaCode.new({
                                                    :user_code => $conf[:user_code],
                                                    :sa => command_args[:sa]
                                                  })
      response = execute(api)

      distid = json_load(response.body)['distributionId'].gsub(/-/, "")
      vendor_code = distid[4, 8].to_i(16)
      sa_type = distid[12, 4].to_i(16)

      {
        :vendor => vendor_code,
        :satype => sa_type,
      }
    end

    def module_exist?(command_args)
      api = Msh::Api::GETHomeModule.new({ })
      api.request = get_vendor_code_sa_type(command_args)

      response = execute(api)
      modules = json_load(response.body)["results"]
      module_ids = []

      modules.each do |smf_module|
        unless module_ids.include?(smf_module["moduleId"])
          module_ids << smf_module["moduleId"]
        end
      end

      unless module_ids.include?(command_args[:module_id].to_i)
        return false
      end

      true
    end

    def need_module_init?(command_args)
      return false unless module_exist?(command_args)

      api = Msh::Api::GETUserUserCodeSaSaCodeConfigWorkingModuleIdPlain.new({
                                                                              :user_code => $conf[:user_code],
                                                                              :sa_code => command_args[:sa]
                                                                            })
      execute(api).code == "404"
    end

    def get_module_type(command_args)
      if need_module_init?(command_args)
        module_init(command_args)
      end

      api = Msh::Api::GETUserUserCodeSaSaCodeConfigWorking.new({
                                                                 :user_code => $conf[:user_code],
                                                                 :sa_code => command_args[:sa]
                                                               })
      response = execute(api)
      type = nil
      json_load(response.body)['results'].each{|e|
        type = e['binary'] ? 'binary' : 'plain' if e['moduleId'] == command_args[:module_id].to_i
      }
      return type
    end

    def has_targetTime?(args, response)
      if args[:targetTime]
        response.content_type = "application/json"
        puts_response(response)
        return true
      else
        return false
      end
    end

    def execute(request)
      sacmapiclient = SacmApiClient.new($conf, request.clone)
      sacmapiclient.start
    end

    def execute_poll(request)
      response = nil
      REQUEST_MAX_POLL.times do
        sleep(REQUEST_POLL_INTERVAL)
        if $output.kind_of?(Msh::Output::Stdout) || $output.kind_of?(Msh::Output::Stderr)
          $output.print "."
        end
        response = execute(request)
        if check_request_response(response)
          $output.print "\n"
          break
        end
      end
      $output.print "\n"
      return response
    end
  end

  module AbstractCommandArgs
    def has_error?
      if self.has_value?(nil)
        $output.puts "#{[self[:command], self[:subcommand]].join(' ')}: required parameter missing."
        return true
      end
    end
  end
end
