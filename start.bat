powershell -command "(new-object -com shell.application).minimizeall()"

REM Usage:
REM   start_etl.bat [--pmc <list-of-events>] [--clocktype <clocktype>] [--gpu <0|1>] [--power <0|1>] ...
REM Parameters:
REM   --pmc <list-of-events> : list of PMC events to collect for CSwitch events
REM   --clocktype <clocktype> : clock type to use. One of Cycle/PerfCounter (default: Cycle)
REM   --no-gpu : disable GPU event collection
REM   --no-power: disable processor power event collection
REM Example:
REM   Enter output directory
REM   Run: start_etl.bat
REM   Run the workload
REM   Run: stop_etl.bat
REM   The resulting trace will be named Merged.etl
SETLOCAL

REM =========================================
REM Parameters that can be overriden by APEQ
REM =========================================
SET clocktype=cycle
SET pmc=InstructionRetired,UnhaltedCoreCycles,LLCReference,LLCMisses,UnhaltedReferenceCycles

REM =========================
REM Default parameter values
REM =========================
IF "%clocktype:~0,1%"=="#" (
	SET clocktype=cycle
)
IF "%pmc:~0,1%"=="#" (
	SET pmc=
)

REM ==========================
REM Trace providers features
REM ==========================
SET enable_gpu=1
SET enable_power=1
SET enable_timers=1
SET enable_win32=1
SET enable_disk=1
set enable_network=1

REM ======================================
REM Command line parsing
REM ======================================
:argparse
IF NOT "%1"=="" (
    SET do_help=False
    IF "%1"=="-h" (
  	    goto print_help
    )
    IF "%1"=="--help" (
  	    goto print_help
    )

    IF "%1"=="--pmc" (
	    IF "%2"=="" (
		   ECHO -E- Missing argument value for --pmc flag
		   EXIT -1
	    )	
	    SET pmc=%2
		SHIFT & SHIFT
	    GOTO argparse
    )

    IF "%1"=="--clocktype" (
	    IF "%2"=="" (
		   ECHO -E- Missing argument value for --clocktype flag
		   EXIT -1
	    )
	    SET clocktype=%2
		SHIFT & SHIFT
	    GOTO argparse
    )

	IF "%1"=="--gpu" (
        IF "%2" NEQ "0" (
            IF "%2" NEQ "1" (
                ECHO -E- Incorrect value specified for --gpu flag. Expected: 0 or 1
                EXIT -1
            )
        )
	    SET enable_gpu=%2
	    SHIFT & SHIFT
	    GOTO argparse
	)

	IF "%1"=="--power" (
        IF "%2" NEQ "0" (
            IF "%2" NEQ "1" (
                ECHO -E- Incorrect value specified for --power flag. Expected: 0 or 1
                EXIT -1
            )
        )
	    SET enable_power=%2
	    SHIFT & SHIFT
	    GOTO argparse
	)

	IF "%1"=="--timers" (
        IF "%2" NEQ "0" (
            IF "%2" NEQ "1" (
                ECHO -E- Incorrect value specified for --timers flag. Expected: 0 or 1
                EXIT -1
            )
        )
	    SET enable_timers=%2
	    SHIFT & SHIFT
	    GOTO argparse
	)

	IF "%1"=="--win32" (
        IF "%2" NEQ "0" (
            IF "%2" NEQ "1" (
                ECHO -E- Incorrect value specified for --win32 flag. Expected: 0 or 1
                EXIT -1
            )
        )
	    SET enable_win32=%2
	    SHIFT & SHIFT
	    GOTO argparse
	)

	IF "%1"=="--disk" (
        IF "%2" NEQ "0" (
            IF "%2" NEQ "1" (
                ECHO -E- Incorrect value specified for --disk flag. Expected: 0 or 1
                EXIT -1
            )
        )
	    SET enable_disk=%2
	    SHIFT & SHIFT
	    GOTO argparse
	)

	IF "%1"=="--network" (
        IF "%2" NEQ "0" (
            IF "%2" NEQ "1" (
                ECHO -E- Incorrect value specified for --network flag. Expected: 0 or 1
                EXIT -1
            )
        )
	    SET enable_network=%2
	    SHIFT & SHIFT
	    GOTO argparse
	)

    ECHO -E- Unrecognized argument: %1
    EXIT -1
)


IF "%pmc%"=="" (
    SET TRACE_PMC=
) ELSE (
	REM PMC counters should be delimited with ":" in command line due to BATCH file limitation that handles , as argument separator
	SET TRACE_PMC=-pmc %pmc::=,% CSWITCH
)
   
REM =====================================
REM Cleaning up existing etl files...
REM =====================================
DEL /Q Merged.etl Kernel.etl DX.etl DXC.etl User.etl

SET TRACE_LARGE_BUFFERS=-BufferSize 1024 -MinBuffers 200 -MaxBuffers 500
SET TRACE_STAND_BUFFERS=-BufferSize 1024 -MinBuffers 60 -MaxBuffers 100
SET TRACE_SMALL_BUFFERS=-BufferSize 1024 -MinBuffers 30 -MaxBuffers 50

REM ==========================
REM Configure event providers
REM ==========================
REM Intel-Assesment-2020 for Athena
SET TRACE_INTEL_ASSESSMENT=d9cfb244-b221-5c49-047b-d2b9a2004377

SET KERNEL_PROVIDERS=LOADER+PROC_THREAD+CSWITCH+DISPATCHER+DPC+INTERRUPT+IDLE_STATES+WDF_INTERRUPT+WDF_DPC+0xA0000080+0xA0000100
SET USER_MODE_PROVIDERS=%TRACE_INTEL_ASSESSMENT%

if %enable_power% NEQ 0 (
    SET KERNEL_PROVIDERS=%KERNEL_PROVIDERS%+POWER
    SET USER_MODE_PROVIDERS=%USER_MODE_PROVIDERS%+Microsoft-Windows-Kernel-Processor-Power
)

if %enable_timers% NEQ 0 (
    SET KERNEL_PROVIDERS=%KERNEL_PROVIDERS%+TIMER
)

if %enable_disk% NEQ 0 (
    SET KERNEL_PROVIDERS=%KERNEL_PROVIDERS%+DISK_IO+FILE_IO+FILE_IO_INIT
)

if %enable_gpu% NEQ 0 (
    SET USER_MODE_PROVIDERS=%USER_MODE_PROVIDERS%+Microsoft-Windows-Dwm-Core
)

if %enable_network% NEQ 0 (
    SET USER_MODE_PROVIDERS=%USER_MODE_PROVIDERS%+Microsoft-Windows-TCPIP
)

if %enable_win32% NEQ 0 (
    REM Microsoft-Windows-Win32k / PointerInput=0x4000000
    REM Micsosoft-Windows-Win32k / UserActivity=0x20000
    SET USER_MODE_PROVIDERS=%USER_MODE_PROVIDERS%+Microsoft-Windows-Win32k:0x4000000
)

REM echo Xperf -on %TRACE_NT_NORMAL% %TRACE_LARGE_BUFFERS% -f Kernel.etl -clocktype %clocktype% %TRACE_PMC%
ECHO Starting logging...

REM =======================
REM Kernel event providers
REM =======================
Xperf -on %KERNEL_PROVIDERS% %TRACE_LARGE_BUFFERS% -f Kernel.etl -clocktype %clocktype% %TRACE_PMC%

REM =====================
REM GPU event providers
REM =====================
SET TRACE_DX=DX
SET TRACE_DXC=Microsoft-Windows-DxgKrnl:0x75
if %enable_gpu% NEQ 0 (    
    Xperf -start DxLogger -on %TRACE_DX% %TRACE_SMALL_BUFFERS% -f DX.etl -clocktype %clocktype%
    Xperf -start DxcLogger -on %TRACE_DXC% %TRACE_STAND_BUFFERS% -f DXC.etl -clocktype %clocktype%
    Xperf -capturestate DxcLogger %TRACE_DXC%
)

REM ===========================
REM User-mode event providers
REM ===========================
if "%USER_MODE_PROVIDERS%" NEQ "" (
    Xperf -start User -on %USER_MODE_PROVIDERS% %TRACE_LARGE_BUFFERS% -f User.etl -clocktype %clocktype%
)

ENDLOCAL

:print_help
ECHO Synopsis: start_etl.bat [--pmc ^<UnhaltedCoreCycles^|InstructionRetired^|...^>] [--clocktype ^<Cycle^|PerfCounter^>]
ECHO          [--gpu ^<0^|1^>] [--power ^<0^|1^>] [--timers ^<0^|1^>] [--win32 ^<0^|1^>] [--disk ^<0^|1^>] [--network ^<0^|1^>]

