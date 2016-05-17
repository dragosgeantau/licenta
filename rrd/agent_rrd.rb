require 'RRD'

class AgentRrd
	def initialize(name)
		@name = name
		@rrd = "#{name}.rrd"
		@startAt = Time.now.to_i

		 RRD.create(
				 @rrd,
				 '--start', "#{@startAt - 60}",
				 '--step', '60',
				 'DS:cpuUsage:GAUGE:600:U:U',
				 'DS:memoryUsage:GAUGE:600:U:U',
				 'DS:swapUsage:GAUGE:600:U:U',
				 'DS:diskUsage:GAUGE:600:U:U',
				 'RRA:AVERAGE:0.5:1:3600'
		)
	end

	def updateState(machineParams)
		cpuUsage = machineParams[:systemCpuUsage].to_i + machineParams[:userCpuUsage].to_i
		memoryUsage = machineParams[:usedMem]
		swapUsage = machineParams[:usedSwap]
		diskUsage = 0
		machineParams['diskUsage'].each do |key, value|
			if key.include? 'sda'
				diskUsage += value.to_i
			end
		end
		RRD.update(
				"#{Time.now.to_i}:#{cpuUsage}:#{memoryUsage}:#{swapUsage}:#{diskUsage}"
		)
	end

	def cpuGraph
		RRD.graph(
			"#{@name}-cpu.png",
			'--title', 'CPU Load',
			'--start', "#{Time.now.to_i - 3600}",
			'--end', "#{Time.now.to_i + 60}",
			'--interlace',
			"DEF:cpu=#{rrd}:cpuUsage:AVERAGE",
			'LINE2:line#FF0000'
		)
	end

	def memGraph
		RRD.graph(
			"#{@name}-mem.png",
			'--title', 'Memory Load',
			'--start', "#{Time.now.to_i - 3600}",
			'--end', "#{Time.now.to_i + 60}",
			'--interlace',
			"DEF:cpu=#{rrd}:memoryUsage:AVERAGE",
			'LINE2:line#FF0000'
		)
	end

	def swapGraph
		RRD.graph(
			"#{@name}-swap.png",
			'--title', 'CPU Load',
			'--start', "#{Time.now.to_i - 3600}",
			'--end', "#{Time.now.to_i + 60}",
			'--interlace',
			"DEF:cpu=#{rrd}:swapUsage:AVERAGE",
			'LINE2:line#FF0000'
		)
	end

	def diskGraph
		RRD.graph(
			"#{name}-disk.png",
			'--title', 'Disk Load',
			'--start', "#{Time.now.to_i - 3600}",
			'--end', "#{Time.now.to_i + 60}",
			'--interlace',
			"DEF:cpu=#{rrd}:diskUsage:AVERAGE",
			'LINE2:line#FF0000'
		)
	end
end