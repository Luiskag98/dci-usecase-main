#!/bin/bash
PIDS=($(pidof -x "${0}" -o $$))
set -euo pipefail

OPTIONS=()

while [ $# -gt 0 ]; do
  case ${1} in
    -s|--server)
    echo "Only iperf clients can be managed with this script!"
    exit 1;;
    -c|--client)
    CLIENT="${2}"
    OPTIONS+=("${1}" "${2}")
    shift
    shift;;
    -p|--port)
    PORT="${2}"
    OPTIONS+=("${1}" "${2}")
    shift
    shift;;
    --kill)
    KILL=1
    shift;;
    --background)
    BACKGROUND=1
    shift;;
    *)
    OPTIONS+=("${1}")
    shift;;
  esac
done

if [ ${KILL:-0} -eq 1 ]; then
  if [ ${#PIDS[@]} -gt 0 ]; then
    for PID in ${PIDS[@]}; do
      CPIDS=($(pgrep -P ${PID}))
      kill ${PID}
      for CPID in ${CPIDS[@]}; do
        kill ${CPID}
      done
    done
  fi
  exit 0
fi

if [ ${#PIDS[@]} -gt 0 ]; then
  echo "Already running in the background! Kill background process first."
  exit 1
fi

if [ -z "${CLIENT:-}" ]; then
  echo "No -c or --client flag found to tell me where the server is..."
  exit 1
fi

if [ ${BACKGROUND:-0} -eq 1 ]; then
  nohup ${0} ${OPTIONS[@]} > /dev/null 2>&1 &
  exit 0
fi

while true; do
  if nc -w 10 -z ${CLIENT} ${PORT:-5201}; then
    sleep .5
    set +e  # ignore non-zero exit codes on iperf3
    /usr/bin/iperf3 ${OPTIONS[@]}
    set -e
  else
    echo "Unable to connect to iperf3 server, retrying in 10 seconds..."
    sleep 10
  fi
done
