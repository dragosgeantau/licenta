require "RRD" 

 name = "test"
 rrd = "#{name}.rrd"
 start = Time.now.to_i

 RRD.create(    
    rrd,
    "--start", "#{start - 1}",
    "--step", "300",
    "DS:a:GAUGE:600:U:U",
    "RRA:AVERAGE:0.5:1:300")
 puts

 puts "updating #{rrd}"
 start.to_i.step(start.to_i + 300 * 300, 60) { |i|
    RRD.update(rrd, "#{i}:#{rand(100)}:#{Math.sin(i / 800) * 50 + 50}")
 }
 puts

 puts "fetching data from #{rrd}"
 (fstart, fend, data, step) = RRD.fetch(rrd, "--start", start.to_s, "--end", 
      (start + 300 * 300).to_s, "AVERAGE")
 puts "got #{data.length} data points from #{fstart} to #{fend}"
 puts

 puts "generating graph #{name}.png"

 RRD.graph(
   "#{name}.png",
    "--title", " RubyRRD Demo", 
    "--start", "#{start+3600}",
    "--end", "start + 1000 min",
    "--interlace", 
    "--imgformat", "PNG",
    "--width=450",
    "DEF:a=#{rrd}:a:AVERAGE",
    "LINE2:a#ffff00") 
 puts
