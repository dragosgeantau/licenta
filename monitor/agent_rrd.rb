require 'RRD'

class AgentRrd
	def initialize(name)
		puts name
		@name = name
		@rrd = "#{@name}.rrd"
		@startAt = Time.now.to_i

		 RRD.create(    
   			@rrd,
		    "--start", "#{@startAt - 60}",
		    "--step", "60",
		    "DS:cpuUsage:GAUGE:600:U:U",
		    "DS:memoryUsage:GAUGE:600:U:U",
		    "DS:swapUsage:GAUGE:600:U:U",
		   	"DS:diskUsage:GAUGE:600:U:U", 
		    "RRA:AVERAGE:0.5:1:3600"
		 )

	end

	def updateState machineParams
		cpuUsage = machineParams["systemCpuUsage"].to_f + machineParams["userCpuUsage"].to_f
		memoryUsage = machineParams["usedMem"].to_i / 1000
		swapUsage = machineParams["usedSwap"].to_i / 1000
		diskUsage = 0
		machineParams.each do |key, value|
			if key.to_s.include? 'sda'
				diskUsage += value.split[3].to_i
			end
		end

		RRD.update(
			@rrd,
			"#{Time.now.to_i}:#{cpuUsage}:#{memoryUsage}:#{swapUsage}:#{diskUsage}"
		)
	end

	def generateGraphs
		cpuGraph
		memGraph
		swapGraph
		diskGraph
	end

	def cpuGraph
		RRD.graph(
			"#{@name}-cpu.png",
			'--title', 'CPU Load',
			'--start', "#{Time.now.to_i - 3600}",
			'--end', "#{Time.now.to_i + 60}",
			'--interlace',
			"DEF:cpu=#{@rrd}:cpuUsage:AVERAGE",
			"LINE2:cpu#FF0000"
		)
	end

	def memGraph
		RRD.graph(
			"#{@name}-mem.png",
			'--title', 'Memory Load',
			'--start', "#{Time.now.to_i - 3600}",
			'--end', "#{Time.now.to_i + 60}",
			'--interlace',
			"DEF:mem=#{@rrd}:memoryUsage:AVERAGE",
			"LINE2:mem#FF0000"
		)
	end

	def swapGraph
		RRD.graph(
			"#{@name}-swap.png",
			'--title', 'CPU Load',
			'--start', "#{Time.now.to_i - 3600}",
			'--end', "#{Time.now.to_i + 60}",
			'--interlace',
			"DEF:swap=#{@rrd}:swapUsage:AVERAGE",
			"LINE2:swap#FF0000"
		)
	end

	def diskGraph
		RRD.graph(
			"#{@name}-disk.png",
			'--title', 'Disk Load',
			'--start', "#{Time.now.to_i - 3600}",
			'--end', "#{Time.now.to_i + 60}",
			'--interlace',
			"DEF:disk=#{@rrd}:diskUsage:AVERAGE",
			"LINE2:disk#FF0000"
		)
	end
end