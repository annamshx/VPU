@echo off
if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)
powershell "C:\Program Files (x86)\Intel\openvino_2021.4.752\deployment_tools\inference_engine\samples\cpp" > build_samples_msvc.bat
pause
echo off
echo -------------------------------------------------------------
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
choco feature enable -n=allowGlobalConfirmation
echo Chocolatey is ready to begin installing packages!
echo -------------------------------------------------------------
echo SETTING CHOCO CACHE LOCATION
echo -------------------------------------------------------------
powershell choco config set cachelocation C:\temp

::choco uninstall visualstudio2019community
echo off
choco install visualstudio2019community 
echo off 
::choco uninstall visualstudio2019buildtools

::choco upgrade visualstudio2019buildtools
echo off
choco install visualstudio2019buildtools
echo off
choco install vcredist140

::choco uninstall vcredist140
echo off
::choco uninstall python

echo -------------------------------------------------------------
   echo PYTHON PACKAGE
::powershell choco uninstall -y --no-progress --source=https://ubit-artifactory-or.intel.com/artifactory/api/nuget/occ-nuget-local python3 --version 3.8.10

echo -------------------------------------------------------------
::choco install python -y --version 3.8.10 --allow-multiple-versions

 echo -------------------------------------------------------------
echo off
::choco uninstall cmake
echo off
choco install cmake -y 

::choco install opencv

start "" /w /b "C:\Program Files (x86)\intel\openvino_2021.4.752\bin\w_openvino_toolkit_p_2021.4.752.exe"


call "C:\Program Files (x86)\intel\openvino_2021.4.752\deployment_tools\model_optimizer\install_prerequisites\install_prerequisites.bat"
echo prerequisites installed

pip install openvino==2021.4
echo off 
::Environment variables 
setx  PATH "%PATH%";"C:\Program Files (x86)\intel\openvino_2021.4.752\bin\setupvars.bat" /m
echo %path%
echo off
call %SystemRoot%\explorer.exe "C:\Users\annamshx\OneDrive - Intel Corporation\Desktop\task manager\task.bat" 


xcopy /s /z "C:\Users\annamshx\OneDrive - Intel Corporation\Desktop\TWS GUI" "C:\Program Files (x86)\Intel\openvino_2021.4.752\deployment_tools\inference_engine\bin\intel64\Release" /E  
call "C:\Program Files (x86)\Intel\openvino_2021.4.752\deployment_tools\inference_engine\samples\cpp>build_samples_msvc.bat"

pause