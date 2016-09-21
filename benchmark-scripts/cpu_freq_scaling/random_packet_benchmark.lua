local dpdk		= require "dpdk"
local memory	= require "memory"
local device	= require "device"
local stats		= require "stats"
local ip4 = require "proto.ip4"
require "utils"

function master(dev)
  setRandomSeed(97629)
  dev = device.config{port=dev}
	device.waitForLinks()
	dpdk.launchLua("counterSlave", {dev})
  dpdk.launchLua("loadSlave", dev, dev:getTxQueue(0), 256)
	dpdk.waitForSlaves()
end

function counterSlave(devices)
  print("counter slave running")
	local counters = {}
	for i, dev in ipairs(devices) do
		counters[i] = stats:newDevRxCounter(dev, "plain")
	end
	while dpdk.running() do
		for _, ctr in ipairs(counters) do
			ctr:update()
		end
		dpdk.sleepMillisIdle(10)
	end
	for _, ctr in ipairs(counters) do
		ctr:update()
	end
end


function loadSlave(dev, queue, numFlows)
  print("Load slave running")
	local mem = memory.createMemPool(function(buf)
		buf:getUdpPacket():fill{
			pktLength = 60,
			ethSrc = queue,
			ethDst = "a0:36:9f:3b:6d:50",
			ip4Dst = "10.0.0.13",
			--ip4Dst = ip4.getRandomAddress().uint32,
			ip4TTL = 60,
			udpSrc = 1234,
			udpDst = 5678,	
		}
	end)
	bufs = mem:bufArray(128)
	local baseIP = parseIPAddress("10.0.0.1")
	local flow = 0
	local ctr = stats:newDevTxCounter(dev, "plain")
	while dpdk.running() do
		bufs:alloc(60)
		for _, buf in ipairs(bufs) do
		  local pkt = buf:getIP4Packet()
      pkt.ip4.dst:set(math.random() * 2^32)
    end
		--for _, buf in ipairs(bufs) do
		--	local pkt = buf:getUdpPacket()
		--	pkt.ip4.src:set(baseIP + flow)
		--	flow = incAndWrap(flow, numFlows)
		--end
		-- UDP checksums are optional, so just IP checksums are sufficient here
		bufs:offloadIPChecksums()
		queue:send(bufs)
		ctr:update()
	end
	ctr:finalize()
end
