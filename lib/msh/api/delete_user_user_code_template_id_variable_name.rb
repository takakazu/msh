require "msh/api/abstract_api"

module Msh
  module Api
    class DELETEUserUserCodeTemplateIdVariableName < Msh::Api::AbstractApi
      private

      def set_param
        @api = "/user/#{@api_request[:user_code]}/template/#{@api_request[:id]}/variable/#{@api_request[:name]}"
        @method = "DELETE"
      end

    end
  end
end
