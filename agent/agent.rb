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

	def run
		loop{
			send_data
			sleep(@sendDataDelay)
		}
	end


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

		def writeResult fileName
		outFile = File.open(fileName, 'w')

		@tempHash.each do |info, value|
			outFile.puts info + ' ' + value	
		end

		outFile.close
	end

		def mysqlInterogation
      serverStatus = {}

      @mysqlServer.query("SHOW STATUS").each do |variable, value|
        serverStatus[variable] = value
      end

      @tempHash['mysqlServer'] = serverStatus
    end

    def categorize hash
      hash = group_hash hash, 0
      hash['Com'] = group_hash hash['Com'], 1
      hash['Com']['show'] = group_hash hash['Com']['show'], 2
      hash['Innodb'] = group_hash hash['Innodb'], 1
      hash['Innodb']['buffer'] = group_hash hash['Innodb']['buffer'], 3
      hash['Handler'] = group_hash hash['Handler'], 1
      hash['Performance'] = group_hash hash['Handler'], 1
      hash['Ssl'] = group_hash hash['Ssl'], 1

      hash
    end

    def group_hash (hash, order = 0)
      result_hash = {}

      hash.each do |variable, value|
        parts = variable.split('_')

        if result_hash[parts[order]]
          result_hash[parts[order]] << [variable, value]
        else
          result_hash[parts[order]] = []
          result_hash[parts[order]] << [variable, value]
        end
      end

      result_hash
    end

    def compress_hash hash
      hash['Other'] = []

      hash.each do |key, value|
        if value.class.to_s == 'Array'
          if value.count == 1
            hash['Other'] << value.flatten
            hash.delete(key)
          end
        else
          hash[key] = compress_hash hash[key]
        end
      end

      hash
    end

end

a = Agent.new('localhost', 64867 , 10, 'localhost', 'root', 'dragos')
a.run
