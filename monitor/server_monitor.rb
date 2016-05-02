require 'socket'
require 'rubygems'
require 'json'
require 'sqlite3'

require_relative 'agent_rrd'

class ServerMonitor

	def initialize(pathToDB = "", port = 64867)
		@agents = {}
		@db = SQLite3::Database.open pathToDB + "monitor_database.sqlite3"
		@port = port
	end

	def getAgentId(client, username)
		sock_domain, remote_port, remote_hostname, remote_ip = client.peeraddr
		#get agent id from db
		agent_id = @db.execute "SELECT id from agents where ip = '#{remote_ip}'"

		#if there is no agent we create one and get the id
		if agent_id.empty?
			@db.execute "INSERT INTO agents(ip, port, host_name) values('#{remote_ip}', '#{remote_port}', '#{remote_hostname}')"
			agent_id = @db.execute "SELECT id from agents where ip = '#{remote_ip}'"
		end

		if username != ''
			user_id = @db.execute "SELECT id FROM users WHERE email = '#{username}'"
			if user_id.empty?
				@db.execute "UPDATE agents SET user_id = null WHERE id = #{agent_id.first.first}"
			else
				@db.execute "UPDATE agents SET user_id = #{user_id.first.first} WHERE id = #{agent_id.first.first}"
			end
		else
			@db.execute "UPDATE agents SET user_id = null WHERE id = #{agent_id.first.first}"
		end

		#reutrn the id
		return agent_id.first.first
	end

	def run
		server = TCPServer.open(@port)
		loop{
			Thread.start(server.accept) do |client|
				username = client.gets
				if username != ''
					username = username.gsub("\n", '')
				end

				agentId = getAgentId client, username
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