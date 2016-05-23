require 'socket'
require 'rubygems'
require 'json'
require 'mysql'

class Agent

  @categoryes = %w(Aborted Binlog Bytes Com_alter Com_create Com_delete Com_drop Com_ha Com_insert Com_a)

	def initialize(host, port = 64867, sendDelay = 10, username = '', db_host, db_user, db_pass)
		@hostname = host
		@port = port
		@sendDataDelay = sendDelay
		@tempHash = {}
		@Id = nil
		@username = username #if no username is specified the agent can be monitored by all
    @mysqlServer = Mysql::new(db_host, db_user, db_pass)
	end

	def writeResult fileName
		outFile = File.open(fileName, 'w')

		@tempHash.each do |info, value|
			outFile.puts info + ' ' + value
		end

		outFile.close
	end

	def run
		loop{
			send_data
			sleep(@sendDataDelay)
		}
	end

	private
		def topCommand outFileName
			%x(top -bn1 > #{outFileName})

			inFile = File.open(outFileName, "r")

			line = inFile.gets
			@tempHash['upTime'] = line.split(' ')[4].gsub(',', '')
			@tempHash['serverTime'] = line.split(' ')[2]
			@tempHash['noOfUsers'] = line.split(' ')[6]

			line = inFile.gets
			@tempHash['noOfTasks'] = line.split(' ')[1]
			@tempHash['activeTasks'] = line.split(' ')[3]
			@tempHash['sleepingTasks'] = line.split(' ')[5]
			@tempHash['stoppedTasks'] = line.split(' ')[7]
			@tempHash['zombieTasks'] = line.split(' ')[9]

			line = inFile.gets
			@tempHash['userCpuUsage'] = line.split(' ')[1]
			@tempHash['systemCpuUsage'] = line.split(' ')[3]
			@tempHash['idleCpuUsage'] = line.split(' ')[7]

			line = inFile.gets
			@tempHash['totalMem'] = line.split(' ')[3]
			@tempHash['usedMem'] = line.split(' ')[7]
			@tempHash['freeMem'] = line.split(' ')[5]

			line = inFile.gets
			@tempHash['totalSwap'] = line.split(' ')[2]
			@tempHash['usedSwap'] = line.split(' ')[6]
			@tempHash['freeSwap'] = line.split(' ')[4]
		end

		def dfCommand outFileName
			%x(df -h > #{outFileName})
			inFile = File.open(outFileName, 'r')
      @tempHash['diskUsage'] = {}
			line = inFile.gets
			while(line = inFile.gets)
				line = line.split(' ')
        @tempHash['diskUsage'][line[0]] = line[1].gsub('G', '').gsub('M', '').gsub('K', '') + ' '
        @tempHash['diskUsage'][line[0]] += line[2].gsub('G', '').gsub('M', '').gsub('K', '') + ' '
        @tempHash['diskUsage'][line[0]] += line[3].gsub('G', '').gsub('M', '').gsub('K', '') + ' '
        @tempHash['diskUsage'][line[0]] += line[4].gsub('%', '') + ' '
			end

		end

		def send_data
		puts "Establishing connection...\n"
		#Opening socket
		server = TCPSocket.open(@hostname, @port)

		server.print(@username + "\n")

		#Reciving status
		puts server.gets

		#gathering data
		topCommand('topCommand.txt')
		dfCommand('dfCommand.txt')
		mysqlInterogation

		puts "Sending data to server..."
		#sending data to server
		server.print(@tempHash.to_json)
		server.print("\n")

		puts "Closing connection...\n\n"
		#closing connection
		server.close
	end

		def mysqlInterogation
      serverStatus = {}

      @mysqlServer.query("SHOW STATUS").each do |variable, value|
        serverStatus[variable] = value
      end

      @tempHash['mysqlServer'] = serverStatus
    end

end

a = Agent.new('localhost', 64867 , 10, 'localhost', 'root', 'dragos')
a.run