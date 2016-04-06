require 'socket'
require 'rubygems'
require 'json'
require_relative 'agent_rrd'

class ServerMonitor

	def initialize(*args)
		@agents = {}
	end

	def run
		server = TCPServer.open(64867)
		loop{
			Thread.start(server.accept) do |client|
				agentId = client.gets.to_i.to_s
				puts "Connected with agent #{agentId}"

				if @agents[agentId].nil?
					puts "Creating agents rrd...\n"
					%x(mkdir rrds/#{agentId})
					@agents[agentId] = {}
					@agents[agentId]['rrd'] = AgentRrd.new("rrds/#{agentId}/#{agentId}")
				end
				client.print "Accepted\n"

				rawData = client.gets.chomp
				puts "Recived data from agent\n"
				machineParams = JSON.parse(rawData)

				puts "Updating agents status...\n"
				@agents[agentId]['rrd'].updateState machineParams

				puts "Generating graphs...\n"
				@agents[agentId]['rrd'].generateGraphs

				puts "Closing connection with agent #{agentId}\n"
				client.close
			end
		}
		server.close
	end

	def getData
		
	end

end

m = ServerMonitor.new
m.run