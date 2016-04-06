require 'RRD'

name = "demo"
rrd = "#{name}.rrd"
startAt = Time.now.to_i

puts 'Creating RRD'

RRD.create(
	rrd,
	'--start', "#{startAt - 60}",
	'--step', '60',
	'DS:cpu:GAUGE:600:U:U',
	'RRA:AVERAGE:0.5:1:3600'
)

puts 'Insearting values in RRD'

startAt.to_i.step(startAt.to_i + 120*60, 60) do |timestamp|
	RRD.update(rrd, "#{timestamp}:#{rand(1000)}")
end

puts 'Generating graph'

RRD.graph(
	"#{name}.png",
	'--title', 'Cpu Load',
	'--start', "#{startAt}",
	'--end', "#{startAt + 6600}",
	'--interlace',
	"DEF:line=#{rrd}:cpu:AVERAGE",
	"LINE2:line#FF0000"
)

puts 'Finished execution'