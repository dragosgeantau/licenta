require 'agent_rrd'

a = AgentRrd.new('asd')
a.updateState Hash.new { |hash, key| hash[key] = 1 }
a.generateGraphs