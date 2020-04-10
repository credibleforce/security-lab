@::!/dos/rocks
@echo off
goto :init

:header
    echo %__NAME% v%__VERSION%
    echo.
    goto :eof

:usage
    echo USAGE:
    echo   %__BAT_NAME% [flags] "required argument" "optional argument" 
    echo.
    echo.  /?, --help                                   shows this help
    echo.  /v, --version                                shows the version
    echo.  -p, --pass SPLUNK_PASSWORD                   splunk web admin password
    echo.  -d, --deployment SPLUNK_DEPLOYMENT_SERVER    splunk deployment server hostname
    goto :eof

:version
    if "%~1"=="full" call :header & goto :eof
    echo %__VERSION%
    goto :eof

:missing_argument
    call :header
    call :usage
    echo.
    echo ****                                   ****
    echo ****    MISSING "REQUIRED ARGUMENT"    ****
    echo ****                                   ****
    echo.
    goto :eof

:init
    set "__NAME=%~n0"
    set "__VERSION=0.0.1"
    set "__YEAR=2020"

    set "__BAT_FILE=%~0"
    set "__BAT_PATH=%~dp0"
    set "__BAT_NAME=%~nx0"

    set "OptHelp="
    set "OptVersion="
    set "OptVerbose="

    set "UnNamedArgument="
    set "UnNamedOptionalArg="
    set "SPLUNK_PASSWORD="
    set "SPLUNK_DEPLOYMENT_SERVER="

:parse
    if "%~1"=="" goto :validate

    if /i "%~1"=="/?"         call :header & call :usage "%~2" & goto :end
    if /i "%~1"=="-?"         call :header & call :usage "%~2" & goto :end
    if /i "%~1"=="--help"     call :header & call :usage "%~2" & goto :end

    if /i "%~1"=="/v"         call :version      & goto :end
    if /i "%~1"=="-v"         call :version      & goto :end
    if /i "%~1"=="--version"  call :version full & goto :end

    if /i "%~1"=="-p"     set "SPLUNK_PASSWORD=%~2"   & shift & shift & goto :parse
    if /i "%~1"=="--pass"     set "SPLUNK_PASSWORD=%~2"   & shift & shift & goto :parse

    if /i "%~1"=="-d"     set "SPLUNK_DEPLOYMENT_SERVER=%~2"   & shift & shift & goto :parse
    if /i "%~1"=="--deployment"     set "SPLUNK_DEPLOYMENT_SERVER=%~2"   & shift & shift & goto :parse

    if not defined UnNamedArgument     set "UnNamedArgument=%~1"     & shift & goto :parse
    if not defined UnNamedOptionalArg  set "UnNamedOptionalArg=%~1"  & shift & goto :parse

    shift
    goto :parse

:validate
    if not defined UnNamedArgument call :missing_argument & goto :end

:main
    echo UnNamedArgument:    "%UnNamedArgument%"

    if defined UnNamedOptionalArg      echo UnNamedOptionalArg: "%UnNamedOptionalArg%"
    if not defined UnNamedOptionalArg  echo UnNamedOptionalArg: not provided

    if defined SPLUNK_PASSWORD               echo SPLUNK_PASSWORD:          "%SPLUNK_PASSWORD%"
    if not defined SPLUNK_PASSWORD           echo SPLUNK_PASSWORD:          not provided

    if defined SPLUNK_DEPLOYMENT_SERVER               echo SPLUNK_DEPLOYMENT_SERVER:          "%SPLUNK_DEPLOYMENT_SERVER%"
    if not defined SPLUNK_DEPLOYMENT_SERVER           echo SPLUNK_DEPLOYMENT_SERVER:          not provided

    msiexec.exe /i splunkforwarder_x64.msi AGREETOLICENSE=yes SPLUNKUSERNAME=admin SPLUNKPASSWORD="%SPLUNK_PASSWORD%" DEPLOYMENT_SERVER="%SPLUNK_DEPLOYMENT_SERVER%:8089" /quiet

:end
    call :cleanup
    exit /B

:cleanup
    REM The cleanup function is only really necessary if you
    REM are _not_ using SETLOCAL.
    set "__NAME="
    set "__VERSION="
    set "__YEAR="

    set "__BAT_FILE="
    set "__BAT_PATH="
    set "__BAT_NAME="

    set "OptHelp="
    set "OptVersion="
    set "OptVerbose="

    set "UnNamedArgument="
    set "UnNamedArgument2="
    set "SPLUNK_PASSWORD="
    set "SPLUNK_DEPLOYMENT_SERVER="

    goto :eof


