module Cyclid
  module UI
    module Controllers
      class Job < Base
        get '/job/:id' do
          authenticate!

          # Get the job data from the API
          begin
            @job = client.job_get(params[:name], params[:id])
          rescue Exception => ex
            STDERR.puts "something went wrong: #{ex}"
            halt 500, 'i have fallen and i can not get up'
          end

          @current_user = current_user

          mustache :job
        end
      end
    end
  end
end
