#!/usr/bin/ruby

require File.expand_path('../../rules/mosync_exe.rb')

work = PipeExeWork.new
work.instance_eval do 
	@SOURCES = ["."]	
	@LIBRARIES = ["mautil", "maui"]
	@EXTRA_LINKFLAGS = " -datasize=256000 -heapsize=128000 -stacksize=16000"
	@NAME = "HelloMAUI"
end

work.invoke
