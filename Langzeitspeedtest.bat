@echo off
if not exist ".\data" goto Installer
:Start
cls
echo Wo soll der log geschrieben werden? "." einfach um aktuellen Pfad zu nutzen!
set /p pfad=
cls
echo Wie viel soll der Test pro durchgang runterladen?
echo Zur auswahl stehen:
echo 1. 100MB (Empholen bei kleiner 100mbit)
echo 2. 1GB (Empholen ab 100mbit)
echo 3. 10GB (Empholen bei groeßer 1000mbit)
echo Gib die Zahl (1-3) an.
set /p große=
cls
echo Wie oft soll der Test laufen? 
set /p anzahl=
cls
echo Zeitlicher Abstand in Minuten:
set /p delay=
cls

set /a delayT=(delay*60)
set round=0

if "%große%"== "1" set mbdef=100
if "%große%"== "2" set mbdef=1000
if "%große%"== "3" set mbdef=10000

cls
if not exist ".\html" mkdir html
if exist ".\html\graph.csv" del ".\html\graph.csv"

echo mbit>>./html/graph.csv
:loop
set /a round=%round%+1
title Speedtest Runde %round%/%anzahl%
rem Zeit Setzen
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)
echo.
if "%große%"== "1" curl http://speed.hetzner.de/100MB.bin --output down.load
if "%große%"== "2" curl http://speed.hetzner.de/1GB.bin --output down.load
if "%große%"== "3" curl http://speed.hetzner.de/10GB.bin --output down.load

rem Zeit Ende setzen
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

rem Zeit DIFF
set /A elapsed=end-start

rem Schreiben
set /A hh=elapsed/(60*60*100), rest=elapsed%%(60*60*100), mm=rest/(60*100), rest%%=60*100, ss=rest/100, cc=rest%%100
if %mm% lss 10 set mm=0%mm%
if %ss% lss 10 set ss=0%ss%
if %cc% lss 10 set cc=0%cc%
set /a hourtos=%hh%*3600
set /a mintos=%mm%*60
set /a sec=hourtos+mintos+ss
set ms=%sec%%cc%0 
set /a mb=(%mbdef%*1000)/ms
cls
set /a mbit=mb*8
set _time=%TIME:~0,2%:%TIME:~3,2%
echo %date%  %_time%  %mbit% mbit/s in %ms% ms >>%pfad%/speedtestlog.txt
echo Der durchschnittliche download war %mb% MB/s (%mbit% mbit/s)
echo %mbit%>>./html/graph.csv
del down.load
if "%round%"== "%anzahl%" goto end
timeout /t %delayT%
goto loop

:end
if not exist ".\data" goto exit
copy ".\data\graph.html" ".\html\graph.html"

if not exist ".\node" goto noNode
if not exist ".\node\www" mkdir ".\node\www"
if not exist ".\node\server.js" goto CreateServerJS
:back
if not exist ".\node\www\index.html" copy ".\data\index.html" ".\node\www\index.html"
if not exist ".\node\www\graph.html" copy ".\html\graph.html" ".\node\www\graph.html"
copy ".\html\graph.csv" ".\node\www\graph.csv"
set /a totalstunden=%anzahl%*%delay%
set /a totaldownload=(%mbdef%*%anzahl%)
goto WriteConfig
:WriteConfigBack
cd ./node
cls
echo Graph bereit!
echo.
node server.js

pause
exit

:WriteConfig
if exist ".\node\www\config.txt" del ".\node\www\config.txt"
echo Download File Größe: %mbdef% MB>>.\node\www\config.txt
echo Zeit zwischen Downloads: %delay% Minuten>>.\node\www\config.txt
echo Anzahl der Messungen: %anzahl%>>.\node\www\config.txt
echo Dieser Speedtest hat %totaldownload% MB verbraucht in %totalstunden% Minuten>>.\node\www\config.txt
goto WriteConfigBack

:CreateServerJS
cd ./node
echo var express = require('express');>>server.js
echo var app = express();>>server.js
echo app.use(express.static(__dirname + '/www'));>>server.js
echo app.listen('3000');>>server.js
echo console.log('Öffne "localhost:3000" in deinem Browser');>>server.js
echo console.log('Schließe dieses Fenster einfach wann du willst');>>server.js
cd ..
goto back

:noNode
cls
echo Kein NodeJS, damit ist kein Graph Moeglich. 
echo Bitte installiere mit dem Installer NodeJS.
echo.
echo Du kannst deine Werte dennoch im speedtestlog.txt am angegebenen Pfad sehen.
pause
exit

:noData
cls
echo Fehler. Datenordner fehlt. Curl scheint nicht auf diesem PC vorhanden zu sein.
pause
exit

:exit
cls
echo Es wurde dem Speedtest nicht erlaubt, zusaetzliche Dateien zu laden.
echo.
echo Speedtest werte koennen im Speedtest Log angeschaut werden. Ein Graph ist nicht verfuegbar
pause 
exit

:Installer
echo Der Langzeitspeedtest braucht fuer das erstellen eines Graphen in HTML, zwei HTML Dateien und NodeJS.
echo Der Speedtest kann auch ohne diese Dateien genutzt werden, erzeugt jedoch nur einen Log mit werten.
echo Sollen diese Daten jetzt heruntergeladen und installiert werden? (y/n)
echo (NodeJS wird als Portable installiert)
set /p installer=
if "%installer%"== "y" goto installerY
if "%installer%"== "Y" goto installerY
goto Start

:installerY
mkdir data
cd ./data
curl https://files.bolverblitz.net/SpeedtestFiles/graph.ht --output graph.html
curl https://files.bolverblitz.net/SpeedtestFiles/index.ht --output index.html
cd ..
curl https://files.bolverblitz.net/SpeedtestFiles/node.zip --output node.zip
curl https://files.bolverblitz.net/SpeedtestFiles/unzip.exe --output unzip.exe
unzip node.zip
del unzip.exe
del node.zip
cd ./node
npm install express
cd ..
goto Start
