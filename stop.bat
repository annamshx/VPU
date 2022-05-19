echo Stopping logging...
xperf -stop DxcLogger
Xperf -stop DxLogger
Xperf -stop User
Xperf.exe -stop

echo All loggers stopped, starting merge...
Xperf -merge Kernel.etl User.etl DXC.etl DX.etl os_trace.etl -compress