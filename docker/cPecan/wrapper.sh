#!/usr/bin/env bash
set -e

# Fix ownership of output files
finish() {
    # Fix ownership of output files
    user_id=$(stat -c '%u:%g' /data)
    chown -R ${user_id} /data
}
trap finish EXIT

# gather time and memory statistics, save everything to 'rle.log'
echo -e "/usr/bin/time -f '\\\\nDEBUG_MAX_MEM:%M\\\\nDEBUG_RUNTIME:%E\\\\n' python /opt/cPecan/marginPhaseIntegration.py --realign_exe /opt/sonLib/bin/cPecanRealign $@\n" > /data/cPecan.log
eval "/usr/bin/time -f '\\nDEBUG_MAX_MEM:%M\\nDEBUG_RUNTIME:%E\\n' python /opt/cPecan/marginPhaseIntegration.py --realign_exe /opt/sonLib/bin/cPecanRealign $@" 2>&1 | tee -a /data/cPecan.log

