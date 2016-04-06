require 'socket'
require 'rubygems'
require 'json'

class Agent

	def initialize(*args)
		@hostname = "localhost"
		@port = 64867
		@sendDataDelay = 10
		@tempHash = {}
		@Id = rand(100)
	end

	def topCommand outFileName
		%x(top -bn1 > #{outFileName})

		inFile = File.open(outFileName, "r")

		line = inFile.gets
		@tempHash['upTime'] = line.split(' ')[4].gsub(',', '')
		@tempHash['serverTime'] = line.split(' ')[2]
		@tempHash['noOfUsers'] = line.split(' ')[5]

		line = inFile.gets
		@tempHash['noOfTasks'] = line.split(' ')[1]
		@tempHash['activeTasks'] = line.split(' ')[3]
		@tempHash['sleepingTasks'] = line.split(' ')[5]
		@tempHash['stoppedTasks'] = line.split(' ')[7]
		@tempHash['zombieTasks'] = line.split(' ')[9]

		line = inFile.gets
		@tempHash['userCpuUsage'] = line.split(' ')[1].split('%').first
		@tempHash['systemCpuUsage'] = line.split(' ')[2].split('%').first
		@tempHash['idleCpuUsage'] = line.split(' ')[4].split('%').first

		line = inFile.gets
		@tempHash['totalMem'] = line.split(' ')[1].split('k').first
		@tempHash['usedMem'] = line.split(' ')[3].split('k').first
		@tempHash['freeMem'] = line.split(' ')[5].split('k').first

		line = inFile.gets
		@tempHash['totalSwap'] = line.split(' ')[1].split('k').first
		@tempHash['usedSwap'] = line.split(' ')[3].split('k').first
		@tempHash['freeSwap'] = line.split(' ')[5].split('k').first
	end

	def dfCommand outFileName
		%x(df -h > #{outFileName})
		inFile = File.open(outFileName, "r")
		line = inFile.gets
		while(line = inFile.gets)
			line = line.split(' ')
			@tempHash[line[0]] = line[1].gsub('G', '').gsub('K', '') + ' '
			@tempHash[line[0]] += line[2].gsub('G', '').gsub('K', '') + ' '
			@tempHash[line[0]] += line[3].gsub('G', '').gsub('K', '') + ' '
			@tempHash[line[0]] += line[4].gsub('%', '') + ' '
		end

	end


	def writeResult fileName
		outFile = File.open(fileName, 'w')

		@tempHash.each do |info, value|
			outFile.puts info + ' ' + value	
		end

		outFile.close
	end

	def send_data
		puts "Establishing connection...\n"
		#Opening socket
		server = TCPSocket.open(@hostname, @port)
		
		#sending id
		puts "Sending id...\n"
		server.print(@Id.to_s + "\n")
		puts server.gets

		#gathering data
		topCommand('topCommand.txt')
		dfCommand('dfCommand.txt')

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

end